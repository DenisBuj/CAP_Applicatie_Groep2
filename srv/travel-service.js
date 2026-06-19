const cds = require('@sap/cds');

/**
 * TravelService implementatie — data-merging tussen TripPin (remote) en de
 * lokale HANA-extensies / Trips-replica / Flights-replica.
 */
module.exports = class TravelService extends cds.ApplicationService {
  async init() {
    const trippin = await cds.connect.to('TripPinService');
    const { AirlineExtension, Flights: PrimeFlights } = cds.entities('primepath');

    // Replicatie bij boot: People, Trips, Flights, Airlines en Airports uit TripPin
    // naar lokale tabellen. Airlines/Airports worden bewust gerepliceerd (i.p.v.
    // live gedelegeerd met `trippin.run(req.query)`) zodat de HR-app niet bij élke
    // request van de trage/flaky remote-service afhangt — dat veroorzaakte een
    // "internal server error" bij het openen zodra TripPin traag was of timeoutte.
    cds.once('served', async () => {
      try {
        await replicatePeople(trippin);
        await replicateTrips(trippin);
        await replicateFlights();
        await replicateAirlines(trippin);
        await replicateAirports(trippin);
        await updateTripDestinations();
        await updateAvailability();
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

    // TripExtensions CRUD: Status/CostCenter synchroon houden in lokale Trips-tabel.
    // Net als de bound action setTripData moet hier ook de beschikbaarheid van de
    // medewerker herberekend worden, anders raakt de "Op reis"-kolom (Team Lead)
    // verouderd wanneer de status via de draft-editor i.p.v. de actie wordt gewijzigd.
    this.after(['CREATE', 'UPDATE'], 'TripExtensions', async (data) => {
      const { Trips } = cds.entities('primepath');
      const owners = new Set();
      for (const ext of toArray(data)) {
        if (!ext.Owner || ext.TripId == null) continue;
        const patch = {};
        if (ext.Status !== undefined)     patch.Status     = ext.Status     ?? 'Gepland';
        if (ext.CostCenter !== undefined) patch.CostCenter = ext.CostCenter ?? '';
        if (Object.keys(patch).length)
          await UPDATE(Trips).where({ Owner: ext.Owner, TripId: ext.TripId }).with(patch);
        if (patch.Status !== undefined) owners.add(ext.Owner);
      }
      for (const owner of owners) await recomputeAvailabilityFor(owner);
    });

    this.after('DELETE', 'TripExtensions', async (_, req) => {
      const { Trips } = cds.entities('primepath');
      const { Owner, TripId } = req.data ?? {};
      if (Owner && TripId != null) {
        await UPDATE(Trips).where({ Owner, TripId }).with({ Status: 'Gepland', CostCenter: '' });
        await recomputeAvailabilityFor(Owner);
      }
    });

    // EmployeeExtensions CRUD: projectcode synchroon houden in de Trips-replica
    // zodat het projectcode-filter (FR-002) op de reizen meteen klopt.
    this.after(['CREATE', 'UPDATE'], 'EmployeeExtensions', async (data) => {
      const { Trips } = cds.entities('primepath');
      for (const ext of toArray(data)) {
        if (!ext.UserName || ext.PrimePathProjectCode === undefined) continue;
        await UPDATE(Trips).where({ Owner: ext.UserName }).with({ ProjectCode: ext.PrimePathProjectCode ?? '' });
      }
    });

    this.after('DELETE', 'EmployeeExtensions', async (_, req) => {
      const { Trips } = cds.entities('primepath');
      const { UserName } = req.data ?? {};
      if (UserName) await UPDATE(Trips).where({ Owner: UserName }).with({ ProjectCode: '' });
    });

    // FR-005: projectcode beheren vanaf het medewerkersprofiel (bound action).
    // Schrijft naar EmployeeExtension en synchroniseert de Trips-replica.
    this.on('setProjectCode', 'Employees', async (req) => {
      const { EmployeeExtension, Trips } = cds.entities('primepath');
      const key  = req.params[req.params.length - 1];
      const UserName = typeof key === 'object' ? key.UserName : key;
      const code = req.data.ProjectCode ?? '';
      if (!UserName) return req.error(400, 'Geen medewerker geselecteerd');

      const existing = await SELECT.one.from(EmployeeExtension).where({ UserName });
      if (existing) await UPDATE(EmployeeExtension).where({ UserName }).with({ PrimePathProjectCode: code });
      else          await INSERT.into(EmployeeExtension).entries({ UserName, PrimePathProjectCode: code });

      await UPDATE(Trips).where({ Owner: UserName }).with({ ProjectCode: code });
      return req.notify?.(`Projectcode bijgewerkt naar "${code || '(leeg)'}"`);
    });

    // FR-008/FR-011: reisstatus + kostenplaats beheren vanaf de reis-objectpagina
    // (Travel Coördinator). Schrijft naar TripExtension en synct de Trips-replica.
    this.on('setTripData', 'Trips', async (req) => {
      const { TripExtension, Trips } = cds.entities('primepath');
      const key = req.params[req.params.length - 1] ?? {};
      const Owner = key.Owner;
      const TripId = key.TripId;
      if (!Owner || TripId == null) return req.error(400, 'Geen reis geselecteerd');
      const Status     = req.data.Status     ?? 'Gepland';
      const CostCenter = req.data.CostCenter ?? '';

      const existing = await SELECT.one.from(TripExtension).where({ Owner, TripId });
      if (existing) await UPDATE(TripExtension).where({ Owner, TripId }).with({ Status, CostCenter });
      else          await INSERT.into(TripExtension).entries({ Owner, TripId, Status, CostCenter });

      await UPDATE(Trips).where({ Owner, TripId }).with({ Status, CostCenter });

      // Beschikbaarheid + planning van de medewerker herberekenen
      await recomputeAvailabilityFor(Owner);

      return req.notify?.(`Reis bijgewerkt — status: ${Status}, kostenplaats: ${CostCenter || '(leeg)'}`);
    });

    // FR-010: preferred-vendor-status toekennen vanaf de airline-objectpagina (HR).
    this.on('setPreferredVendor', 'Airlines', async (req) => {
      const { AirlineExtension } = cds.entities('primepath');
      const key = req.params[req.params.length - 1] ?? {};
      const AirlineCode = typeof key === 'object' ? key.AirlineCode : key;
      if (!AirlineCode) return req.error(400, 'Geen airline geselecteerd');
      const pv = req.data.PreferredVendor ?? false;

      const existing = await SELECT.one.from(AirlineExtension).where({ AirlineCode });
      if (existing) await UPDATE(AirlineExtension).where({ AirlineCode }).with({ PreferredVendor: pv });
      else          await INSERT.into(AirlineExtension).entries({ AirlineCode, PreferredVendor: pv });
      return req.notify?.(`Preferred vendor ${pv ? 'aangezet' : 'uitgezet'} voor ${AirlineCode}`);
    });

    // Value-help voor de reisstatus (vaste-waarden dropdown in filter + editor).
    this.on('READ', 'TripStatusValues', () => ([
      { code: 'Gepland',  name: 'Gepland'  },
      { code: 'Onderweg', name: 'Onderweg' },
      { code: 'Afgerond', name: 'Afgerond' },
    ]));

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
      return { TotalTrips: Number(cnt), TravelersNow: new Set(rows.map(r => r.Owner)).size };
    });

    await super.init();
  }
};

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

const CRITICALITY = { Gepland: 0, Onderweg: 2, Afgerond: 3 };

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
 * Repliceert TripPin `Airlines` naar de lokale primepath.Airlines-tabel.
 * Hierdoor leest de HR/Insights-app (FR-009) uit de DB i.p.v. live van de remote
 * service — dat voorkomt de "internal server error" bij traagheid/timeouts van
 * TripPin. PreferredVendor + FlightCount worden in de after-handler toegevoegd.
 */
async function replicateAirlines(trippin) {
  const { Airlines } = cds.entities('primepath');
  const remote = await trippin.run(
    SELECT.from('TripPinService.Airlines').columns('AirlineCode', 'Name')
  );
  if (!remote.length) return;
  const rows = remote.map((a) => ({ AirlineCode: a.AirlineCode, Name: a.Name }));
  await DELETE.from(Airlines);
  await INSERT.into(Airlines).entries(rows);
  cds.log('travel').info(`Airlines-replicatie: ${rows.length} airlines uit TripPin`);
}

/**
 * Repliceert TripPin `Airports` naar de lokale primepath.Airports-tabel
 * (geen verrijking). Location bewust weggelaten (genest complex-type, buiten MVP).
 */
async function replicateAirports(trippin) {
  const { Airports } = cds.entities('primepath');
  const remote = await trippin.run(
    SELECT.from('TripPinService.Airports').columns('IcaoCode', 'IataCode', 'Name')
  );
  if (!remote.length) return;
  const rows = remote.map((a) => ({ IcaoCode: a.IcaoCode, IataCode: a.IataCode, Name: a.Name }));
  await DELETE.from(Airports);
  await INSERT.into(Airports).entries(rows);
  cds.log('travel').info(`Airports-replicatie: ${rows.length} luchthavens uit TripPin`);
}

/**
 * Repliceert alle TripPin-reizen naar primepath.Trips via People $expand=Trips.
 * Verrijkt elke reis met Status/CostCenter uit TripExtension (Owner+TripId).
 * Reizen zonder extensie krijgen default Status='Gepland' en CostCenter=''.
 */
async function replicateTrips(trippin) {
  const { Trips, TripExtension, EmployeeExtension } = cds.entities('primepath');
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
        Status: 'Gepland', CostCenter: '', ProjectCode: '',
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

  // FR-002: projectcode per medewerker meenemen zodat reizen op projectcode
  // filterbaar zijn (de projectcode hoort bij de Owner via EmployeeExtension).
  const empExts = await SELECT.from(EmployeeExtension);
  const projByUser = new Map(empExts.map((e) => [e.UserName, e.PrimePathProjectCode ?? '']));
  for (const row of rows) {
    row.ProjectCode = projByUser.get(row.Owner) ?? '';
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
          FromCountry:     f.From?.Location?.City?.CountryRegion ?? '',
          ToAirport:       f.To?.IcaoCode         ?? '',
          ToAirportName:   f.To?.Name             ?? '',
          ToCountry:       f.To?.Location?.City?.CountryRegion   ?? '',
          StartsAt:        f.StartsAt ?? ref.StartsAt,
          EndsAt:          f.EndsAt   ?? ref.EndsAt,
        };
      } catch { return { ...ref, AirlineCode: '', AirlineName: '', FromAirport: '', FromAirportName: '', FromCountry: '', ToAirport: '', ToAirportName: '', ToCountry: '' }; }
    }))
  ).filter(Boolean);

  await DELETE.from(Flights);
  if (rows.length) await INSERT.into(Flights).entries(rows);
  cds.log('travel').info(`Flights-replicatie: ${rows.length} vluchten uit TripPin`);
}

/**
 * Leidt per reis de bestemming (land + aankomstluchthaven) af uit de vluchten,
 * zodat de coördinator de reizenlijst op land/luchthaven kan filteren
 * ("wie reist naar de VS en via welke luchthaven?"). De bestemming = de
 * aankomst van de laatste vlucht van de reis (op StartsAt). Reizen zonder
 * gerepliceerde vlucht blijven leeg (TripPin levert niet voor elke reis vluchten).
 */
async function updateTripDestinations() {
  const { Trips, Flights } = cds.entities('primepath');
  const flights = await SELECT.from(Flights)
    .columns('Owner', 'TripId', 'ToAirportName', 'ToCountry', 'StartsAt')
    .orderBy('StartsAt');

  // Op StartsAt oplopend → de laatste die we per reis zien is de verste aankomst.
  const lastArrival = new Map();
  for (const f of flights) lastArrival.set(`${f.Owner}/${f.TripId}`, f);

  let updated = 0;
  for (const f of lastArrival.values()) {
    await UPDATE(Trips).where({ Owner: f.Owner, TripId: f.TripId }).with({
      DestinationCountry: f.ToCountry ?? '',
      DestinationAirport: f.ToAirportName ?? '',
    });
    updated++;
  }
  cds.log('travel').info(`Bestemmingen afgeleid voor ${updated} reizen`);
}

/**
 * Beschikbaarheid van medewerkers afleiden voor de Team Lead: een medewerker is
 * "op reis" als hij minstens één reis met status 'Onderweg' heeft. Wordt bij boot
 * berekend (na de Trips-replicatie) en daarna bijgewerkt bij elke statuswijziging.
 */
/** Bouwt de beschikbaarheids-/planningsvelden op uit de twee booleans. */
function availabilityFields(traveling, planned) {
  return {
    IsTraveling:             !!traveling,
    HasPlannedTrip:          !!planned,
    Availability:            traveling ? 'Op reis' : 'Beschikbaar',
    AvailabilityCriticality: traveling ? 2 : 3,
    PlannedLabel:            planned ? 'Gepland' : '—',
  };
}

/**
 * Herberekent de beschikbaarheids-/planningsvelden voor één medewerker op basis
 * van de actuele reisstatussen in de Trips-replica. Gebruikt door zowel de
 * bound action setTripData als de TripExtensions draft-CRUD, zodat de "Op reis"-
 * kolom (Team Lead) nooit verouderd raakt — ongeacht hoe de status wijzigt.
 */
async function recomputeAvailabilityFor(Owner) {
  if (!Owner) return;
  const { People, Trips } = cds.entities('primepath');
  const onTrip  = await SELECT.one.from(Trips).where({ Owner, Status: 'Onderweg' });
  const planned = await SELECT.one.from(Trips).where({ Owner, Status: 'Gepland' });
  await UPDATE(People).where({ UserName: Owner }).with(availabilityFields(onTrip, planned));
}

async function updateAvailability() {
  const { People, Trips } = cds.entities('primepath');
  const onderweg = await SELECT.from(Trips).columns('Owner').where({ Status: 'Onderweg' });
  const gepland  = await SELECT.from(Trips).columns('Owner').where({ Status: 'Gepland' });
  const traveling = new Set(onderweg.map((t) => t.Owner));
  const planned   = new Set(gepland.map((t) => t.Owner));
  const people = await SELECT.from(People).columns('UserName');
  for (const p of people)
    await UPDATE(People).where({ UserName: p.UserName })
      .with(availabilityFields(traveling.has(p.UserName), planned.has(p.UserName)));
  cds.log('travel').info(`Beschikbaarheid: ${traveling.size} op reis, ${planned.size} met geplande reis`);
}
