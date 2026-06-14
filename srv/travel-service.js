const cds = require('@sap/cds');

/**
 * TravelService implementatie — data-merging tussen TripPin (remote) en de
 * lokale HANA-extensies / Trips-replica / Flights-replica.
 */
module.exports = class TravelService extends cds.ApplicationService {
  async init() {
    const trippin = await cds.connect.to('TripPinService');
    const { AirlineExtension, Flights: PrimeFlights } = cds.entities('primepath');

    // READ-delegatie naar TripPin voor remote-gebaseerde entiteiten
    this.on('READ', 'Airlines', (req) => trippin.run(req.query));
    this.on('READ', 'Airports', (req) => trippin.run(req.query));

    // Replicatie bij boot: People, Trips en Flights uit TripPin naar lokale tabellen
    cds.once('served', async () => {
      try {
        await replicatePeople(trippin);
        await replicateTrips(trippin);
        await replicateFlights();
      } catch (e) {
        cds.log('travel').warn('Replicatie mislukt:', e.message);
      }
    });

    // Airlines: PreferredVendor + FlightCount toevoegen (FR-009)
    this.after('READ', 'Airlines', async (rows) => {
      const list = toArray(rows);
      if (!list.length) return;
      const codes = list.map((r) => r.AirlineCode);

      const [extRows, flightRows] = await Promise.all([
        SELECT.from(AirlineExtension).where({ AirlineCode: { in: codes } }),
        SELECT.from(PrimeFlights).where({ AirlineCode: { in: codes } }).columns('AirlineCode'),
      ]);

      const byExt = index(extRows, 'AirlineCode');
      const flightCount = {};
      for (const f of flightRows)
        flightCount[f.AirlineCode] = (flightCount[f.AirlineCode] ?? 0) + 1;

      for (const r of list) {
        const x = byExt[r.AirlineCode];
        r.PreferredVendor = x ? !!x.PreferredVendor : false;
        r.FlightCount     = flightCount[r.AirlineCode] ?? 0;
      }
    });

    // Trips: StatusCriticality berekenen (Status is een echte DB-kolom)
    this.after('READ', 'Trips', (rows) => {
      for (const r of toArray(rows))
        r.StatusCriticality = CRITICALITY[r.Status] ?? 1;
    });

    // TripExtensions CRUD: Status/CostCenter synchroon houden in lokale Trips-tabel
    this.after(['CREATE', 'UPDATE'], 'TripExtensions', async (data) => {
      const { Trips } = cds.entities('primepath');
      for (const ext of toArray(data)) {
        if (!ext.Owner || ext.TripId == null) continue;
        const patch = {};
        if (ext.Status !== undefined)     patch.Status     = ext.Status     ?? 'Gepland';
        if (ext.CostCenter !== undefined) patch.CostCenter = ext.CostCenter ?? '';
        if (Object.keys(patch).length)
          await UPDATE(Trips).where({ Owner: ext.Owner, TripId: ext.TripId }).with(patch);
      }
    });

    this.after('DELETE', 'TripExtensions', async (_, req) => {
      const { Trips } = cds.entities('primepath');
      const { Owner, TripId } = req.data ?? {};
      if (Owner && TripId != null)
        await UPDATE(Trips).where({ Owner, TripId }).with({ Status: 'Gepland', CostCenter: '' });
    });

    // ---- KPI-functies (FR-001) -------------------------------------------

    /**
     * TotalTrips: totaal aantal reizen in het systeem.
     * Testen: GET http://localhost:4004/travel/TotalTrips()
     */
    this.on('TotalTrips', async () => {
      const { Trips } = cds.entities('primepath');
      const rows = await SELECT.from(Trips).columns('count(*) as cnt');
      return rows[0]?.cnt ?? 0;
    });

    /**
     * TravelersNow: medewerkers momenteel op reis (StartsAt ≤ vandaag ≤ EndsAt).
     * Testen: GET http://localhost:4004/travel/TravelersNow()
     */
    this.on('TravelersNow', async () => {
      const { Trips } = cds.entities('primepath');
      const today = new Date().toISOString();
      const rows = await SELECT.from(Trips).where({ StartsAt: { '<=': today }, EndsAt: { '>=': today } });
      const unique = new Set(rows.map((r) => r.Owner));
      return unique.size;
    });

    /**
     * TopAirlines: airlines gesorteerd op aantal vluchten (niet budget — FR-009).
     * Testen: GET http://localhost:4004/travel/TopAirlines()
     */
    this.on('TopAirlines', async () => {
      const flightRows = await SELECT.from(PrimeFlights).columns('AirlineCode');
      const countMap = {};
      for (const f of flightRows)
        if (f.AirlineCode) countMap[f.AirlineCode] = (countMap[f.AirlineCode] ?? 0) + 1;

      const sorted = Object.entries(countMap)
        .sort(([, a], [, b]) => b - a)
        .map(([code, cnt]) => ({ AirlineCode: code, FlightCount: cnt }));

      // Voeg airline-naam toe uit TripPin
      const result = [];
      for (const item of sorted) {
        const airline = await trippin.run(
          SELECT.one.from('TripPinService.Airlines').where({ AirlineCode: item.AirlineCode })
        );
        result.push({
          AirlineCode: item.AirlineCode,
          Name:        airline?.Name ?? item.AirlineCode,
          FlightCount: item.FlightCount,
        });
      }
      return result;
    });

    // KPISummary singleton (FR-001): TotalTrips + TravelersNow in-memory berekend.
    this.on('READ', 'KPISummary', async () => {
      const { Trips } = cds.entities('primepath');
      const [{ cnt }] = await SELECT.from(Trips).columns('count(*) as cnt');
      const today = new Date().toISOString();
      const rows  = await SELECT.from(Trips).where({ StartsAt: { '<=': today }, EndsAt: { '>=': today } });
      return { dummy: 1, TotalTrips: Number(cnt), TravelersNow: new Set(rows.map(r => r.Owner)).size };
    });

    await super.init();
  }
};

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

const CRITICALITY = { Gepland: 1, Onderweg: 2, Afgerond: 3 };

function toArray(x) {
  return Array.isArray(x) ? x : x ? [x] : [];
}

function index(arr, key) {
  return Object.fromEntries(arr.map((o) => [o[key], o]));
}

const GENDER = { 0: 'Male', 1: 'Female', 2: 'Unknown' };

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
 * Repliceert alle TripPin-reizen naar primepath.Trips via People $expand=Trips.
 * Verrijkt elke reis met Status/CostCenter uit TripExtension (Owner+TripId).
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
        Owner: person.UserName, TripId: t.TripId,
        Name: t.Name ?? '', Description: t.Description ?? '',
        StartsAt: t.StartsAt, EndsAt: t.EndsAt, Budget: t.Budget,
        Status: 'Gepland', CostCenter: '',
      });
    }
  }
  if (!rows.length) return;

  const exts   = await SELECT.from(TripExtension);
  const extMap = new Map(exts.map((e) => [`${e.Owner}/${e.TripId}`, e]));
  for (const row of rows) {
    const ext = extMap.get(`${row.Owner}/${row.TripId}`);
    if (ext) { row.Status = ext.Status ?? 'Gepland'; row.CostCenter = ext.CostCenter ?? ''; }
  }

  await DELETE.from(Trips);
  await INSERT.into(Trips).entries(rows);
  cds.log('travel').info(`Trips-replicatie: ${rows.length} reizen uit TripPin`);
}

/**
 * Repliceert TripPin-vluchten naar primepath.Flights via twee stappen:
 *
 * Stap 1 — Per trip: PlanItems?$filter=isof('Trippin.Flight') → PlanItemIds
 *   (isof-filter werkt op de base-type collection; type-cast path /Microsoft...Flight
 *   gooit HTTP 500 op TripPin RESTier)
 *
 * Stap 2 — Per vlucht: PlanItems({id})/Trippin.Flight?$expand=Airline,From,To
 *   (individuele type-cast navigatie wel ondersteund → geeft AirlineCode + IcaoCodes)
 *
 * Beide stappen lopen parallel voor maximale snelheid.
 * Reden voor native fetch: trippin.send/run valideren de OData-query tegen het
 * CDS-model; het CAP-model kent Airline/From/To niet op PlanItem (base type).
 */
async function replicateFlights() {
  const { Flights, Trips } = cds.entities('primepath');

  // TripPin base-URL uit CDS-configuratie (lokaal) of fallback
  const baseUrl = (cds.env.requires?.TripPinService?.credentials?.url ?? '').replace(/\/$/, '')
               || 'https://services.odata.org/TripPinRESTierService';

  const localTrips = await SELECT.from(Trips).columns('Owner', 'TripId');

  // Stap 1: voor elke trip de flight-PlanItemIds ophalen (parallel)
  const flightRefs = (
    await Promise.all(localTrips.map(async (trip) => {
      try {
        const owner = encodeURIComponent(trip.Owner);
        const url   = `${baseUrl}/People('${owner}')/Trips(${trip.TripId})`
                    + `/PlanItems?$filter=isof('Trippin.Flight')`;
        const resp  = await fetch(url, { headers: { Accept: 'application/json' } });
        if (!resp.ok) return [];
        const data  = await resp.json();
        return (data.value ?? []).map((item) => ({
          Owner:        trip.Owner,
          TripId:       trip.TripId,
          PlanItemId:   item.PlanItemId,
          FlightNumber: item.FlightNumber ?? '',
          StartsAt:     item.StartsAt,
          EndsAt:       item.EndsAt,
        }));
      } catch { return []; }
    }))
  ).flat();

  // Stap 2: per vlucht Airline + From + To ophalen (parallel)
  const rows = (
    await Promise.all(flightRefs.map(async (ref) => {
      try {
        const owner = encodeURIComponent(ref.Owner);
        const url   = `${baseUrl}/People('${owner}')/Trips(${ref.TripId})`
                    + `/PlanItems(${ref.PlanItemId})/Trippin.Flight?$expand=Airline,From,To`;
        const resp  = await fetch(url, { headers: { Accept: 'application/json' } });
        if (!resp.ok) return { ...ref, AirlineCode: '', FromAirport: '', ToAirport: '' };
        const f = await resp.json();
        return {
          Owner:           ref.Owner,
          TripId:          ref.TripId,
          PlanItemId:      ref.PlanItemId,
          FlightNumber:    f.FlightNumber ?? ref.FlightNumber,
          AirlineCode:     f.Airline?.AirlineCode ?? '',
          AirlineName:     f.Airline?.Name        ?? '',
          FromAirport:     f.From?.IcaoCode       ?? '',
          FromAirportName: f.From?.Name           ?? '',
          ToAirport:       f.To?.IcaoCode         ?? '',
          ToAirportName:   f.To?.Name             ?? '',
          StartsAt:        f.StartsAt ?? ref.StartsAt,
          EndsAt:          f.EndsAt   ?? ref.EndsAt,
        };
      } catch { return { ...ref, AirlineCode: '', AirlineName: '', FromAirport: '', FromAirportName: '', ToAirport: '', ToAirportName: '' }; }
    }))
  ).filter(Boolean);

  await DELETE.from(Flights);
  if (rows.length) await INSERT.into(Flights).entries(rows);
  cds.log('travel').info(`Flights-replicatie: ${rows.length} vluchten uit TripPin`);
}
