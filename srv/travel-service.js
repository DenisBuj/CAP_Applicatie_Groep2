const cds = require('@sap/cds');

/**
 * TravelService implementatie — data-merging tussen TripPin (remote) en de
 * lokale HANA-extensies / Trips-replica.
 */
module.exports = class TravelService extends cds.ApplicationService {
  async init() {
    const trippin = await cds.connect.to('TripPinService');
    const { AirlineExtension } = cds.entities('primepath');

    // READ-delegatie naar TripPin voor remote-gebaseerde entiteiten
    this.on('READ', 'Airlines', (req) => trippin.run(req.query));
    this.on('READ', 'Airports', (req) => trippin.run(req.query));

    // Replicatie bij boot: People en alle Trips uit TripPin naar lokale tabellen
    cds.once('served', async () => {
      try {
        await replicatePeople(trippin);
        await replicateTrips(trippin);
      } catch (e) {
        cds.log('travel').warn('Replicatie mislukt:', e.message);
      }
    });

    // Airlines: PreferredVendor uit AirlineExtension toevoegen
    this.after('READ', 'Airlines', async (rows) => {
      const list = toArray(rows);
      if (!list.length) return;
      const ext = await SELECT.from(AirlineExtension)
        .where({ AirlineCode: { in: list.map((r) => r.AirlineCode) } });
      const byKey = index(ext, 'AirlineCode');
      for (const r of list) {
        const x = byKey[r.AirlineCode];
        r.PreferredVendor = x ? !!x.PreferredVendor : false;
      }
    });

    // Trips: StatusCriticality berekenen (Status is nu een echte DB-kolom)
    this.after('READ', 'Trips', (rows) => {
      for (const r of toArray(rows)) {
        r.StatusCriticality = CRITICALITY[r.Status] ?? 1;
      }
    });

    // TripExtensions CRUD: Status/CostCenter synchroon houden in lokale Trips-tabel.
    // Zo reflecteert de geaggregeerde Trips-set altijd de laatste PrimePath-verrijking,
    // ook zonder herstart.
    this.after(['CREATE', 'UPDATE'], 'TripExtensions', async (data) => {
      const { Trips } = cds.entities('primepath');
      for (const ext of toArray(data)) {
        if (!ext.Owner || ext.TripId == null) continue;
        const patch = {};
        if (ext.Status !== undefined)    patch.Status     = ext.Status     ?? 'Gepland';
        if (ext.CostCenter !== undefined) patch.CostCenter = ext.CostCenter ?? '';
        if (Object.keys(patch).length)
          await UPDATE(Trips).where({ Owner: ext.Owner, TripId: ext.TripId }).with(patch);
      }
    });

    // Bij verwijdering van een extensie: herstel defaults in de lokale Trips-tabel
    this.after('DELETE', 'TripExtensions', async (_, req) => {
      const { Trips } = cds.entities('primepath');
      const { Owner, TripId } = req.data ?? {};
      if (Owner && TripId != null)
        await UPDATE(Trips).where({ Owner, TripId }).with({ Status: 'Gepland', CostCenter: '' });
    });

    await super.init();
  }
};

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

// Fiori criticality: 1=neutraal (Gepland), 2=kritisch/oranje (Onderweg), 3=positief/groen (Afgerond)
const CRITICALITY = { Gepland: 1, Onderweg: 2, Afgerond: 3 };

function toArray(x) {
  return Array.isArray(x) ? x : x ? [x] : [];
}

function index(arr, key) {
  return Object.fromEntries(arr.map((o) => [o[key], o]));
}

const GENDER = { 0: 'Male', 1: 'Female', 2: 'Unknown' };

/**
 * Repliceert TripPin People naar de lokale primepath.People-tabel.
 * Nodig zodat Employees lokaal joinbaar is (drill-down, filters, KPI's).
 */
async function replicatePeople(trippin) {
  const { People } = cds.entities('primepath');
  const remote = await trippin.run(
    SELECT.from('TripPinService.People').columns(
      'UserName', 'FirstName', 'LastName', 'MiddleName', 'Gender', 'Age'
    )
  );
  if (!remote.length) return;
  const rows = remote.map((p) => ({
    UserName:   p.UserName,
    FirstName:  p.FirstName,
    LastName:   p.LastName,
    MiddleName: p.MiddleName,
    Gender:     typeof p.Gender === 'number' ? GENDER[p.Gender] : p.Gender,
    Age:        p.Age,
  }));
  await DELETE.from(People);
  await INSERT.into(People).entries(rows);
  cds.log('travel').info(`People-replicatie: ${rows.length} medewerkers`);
}

/**
 * Repliceert ALLE TripPin-reizen naar primepath.Trips via People $expand=Trips.
 * TripPin heeft geen top-level /Trips set; we aggregeren via alle personen.
 * Elke reis wordt verrijkt met Status/CostCenter uit TripExtension (Owner+TripId).
 * Reizen zonder extensie krijgen default Status='Gepland' en CostCenter=''.
 */
async function replicateTrips(trippin) {
  const { Trips, TripExtension } = cds.entities('primepath');

  const people = await trippin.run(
    SELECT.from('TripPinService.People').columns(
      'UserName',
      { ref: ['Trips'], expand: ['TripId', 'Name', 'Description', 'StartsAt', 'EndsAt', 'Budget'] }
    )
  );

  const rows = [];
  for (const person of people) {
    for (const t of person.Trips ?? []) {
      rows.push({
        Owner:       person.UserName,
        TripId:      t.TripId,
        Name:        t.Name        ?? '',
        Description: t.Description ?? '',
        StartsAt:    t.StartsAt,
        EndsAt:      t.EndsAt,
        Budget:      t.Budget,
        Status:      'Gepland',
        CostCenter:  '',
      });
    }
  }

  if (!rows.length) return;

  // Verrijk met lokale TripExtension-data (eigen PrimePath-velden)
  const exts = await SELECT.from(TripExtension);
  const extMap = new Map(exts.map((e) => [`${e.Owner}/${e.TripId}`, e]));
  for (const row of rows) {
    const ext = extMap.get(`${row.Owner}/${row.TripId}`);
    if (ext) {
      row.Status     = ext.Status     ?? 'Gepland';
      row.CostCenter = ext.CostCenter ?? '';
    }
  }

  await DELETE.from(Trips);
  await INSERT.into(Trips).entries(rows);
  cds.log('travel').info(`Trips-replicatie: ${rows.length} reizen uit TripPin`);
}
