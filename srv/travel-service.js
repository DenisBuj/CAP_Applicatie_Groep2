const cds = require('@sap/cds');

/**
 * TravelService implementatie — de data-merging tussen TripPin (remote) en de
 * lokale HANA-extensies.
 */
module.exports = class TravelService extends cds.ApplicationService {
  async init() {
    const trippin = await cds.connect.to('TripPinService');
    const { AirlineExtension } = cds.entities('primepath');

    // --- READ-delegatie naar TripPin voor de remote-gebaseerde entiteiten ---
    // (projecties op een @cds.persistence.skip remote-entiteit worden niet
    //  automatisch geserveerd; we sturen de query door naar TripPin)
    // Employees is nu lokaal (People-replica), dus niet meer doorsturen.
    this.on('READ', 'Airlines', (req) => trippin.run(req.query));
    this.on('READ', 'Airports', (req) => trippin.run(req.query));

    // --- Replicatie: TripPin People -> lokale People-tabel (bij elke boot) ---
    cds.once('served', async () => {
      try {
        await replicatePeople(trippin);
      } catch (e) {
        cds.log('travel').warn('People-replicatie mislukt:', e.message);
      }
    });

    // --- Airlines: PreferredVendor uit AirlineExtension toevoegen ---
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

    // --- Trips: lokale Status/Budget verrijken met TripPin reisdetails ---
    this.after('READ', 'Trips', async (rows) => {
      const list = toArray(rows);
      if (!list.length) return;
      const details = await getTripDetails(trippin);
      for (const r of list) {
        const d = details.get(tripKey(r.Owner, r.TripId));
        if (!d) continue;
        r.Name = d.Name;
        r.Description = d.Description;
        r.StartsAt = d.StartsAt;
        r.EndsAt = d.EndsAt;
        // Budget komt read-only uit TripPin
        r.Budget = d.Budget;
      }
      // criticality voor gekleurde status-cel in Fiori
      for (const r of list) r.StatusCriticality = CRITICALITY[r.Status] ?? 0;
    });

    await super.init();
  }
};

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

// Fiori criticality: 1=neutraal, 2=kritisch/oranje, 3=positief/groen
const CRITICALITY = { Gepland: 1, Onderweg: 2, Afgerond: 3 };

function toArray(x) {
  return Array.isArray(x) ? x : x ? [x] : [];
}

function index(arr, key) {
  return Object.fromEntries(arr.map((o) => [o[key], o]));
}

// TripPin PersonGender enum -> leesbare string
const GENDER = { 0: 'Male', 1: 'Female', 2: 'Unknown' };

/**
 * Repliceert de TripPin People naar de lokale `primepath.People`-tabel, zodat
 * Employees lokaal joinbaar/associeerbaar is (drill-down, filters, KPI's).
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
    UserName: p.UserName,
    FirstName: p.FirstName,
    LastName: p.LastName,
    MiddleName: p.MiddleName,
    Gender: typeof p.Gender === 'number' ? GENDER[p.Gender] : p.Gender,
    Age: p.Age,
  }));
  await DELETE.from(People);
  await INSERT.into(People).entries(rows);
  cds.log('travel').info(`People-replicatie: ${rows.length} medewerkers uit TripPin`);
}

// Samengestelde sleutel Owner + TripId (gedeelde trips delen een TripId).
function tripKey(owner, tripId) {
  return `${owner}/${tripId}`;
}

/**
 * Haalt alle TripPin-reisdetails op (People $expand=Trips) en bouwt een
 * Map "Owner/TripId" -> { Owner, Name, Description, StartsAt, EndsAt, Budget }.
 * TripPin heeft geen top-level /Trips set, dus we lopen via People. Gedeelde
 * trips blijven per eigenaar als aparte sleutel behouden (geen dedup).
 */
async function getTripDetails(trippin) {
  const people = await trippin.run(
    SELECT.from('TripPinService.People').columns(
      'UserName',
      { ref: ['Trips'], expand: ['*'] }
    )
  );
  const map = new Map();
  for (const person of people) {
    for (const t of person.Trips || []) {
      map.set(tripKey(person.UserName, t.TripId), {
        Owner: person.UserName,
        Name: t.Name,
        Description: t.Description,
        StartsAt: t.StartsAt,
        EndsAt: t.EndsAt,
        Budget: t.Budget,
      });
    }
  }
  return map;
}
