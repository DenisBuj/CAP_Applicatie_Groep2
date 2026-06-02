const cds = require('@sap/cds');

/**
 * TravelService implementatie — de data-merging tussen TripPin (remote) en de
 * lokale HANA-extensies.
 */
module.exports = class TravelService extends cds.ApplicationService {
  async init() {
    const trippin = await cds.connect.to('TripPinService');
    const { EmployeeExtension, AirlineExtension } = cds.entities('primepath');

    // --- READ-delegatie naar TripPin voor de remote-gebaseerde entiteiten ---
    // (projecties op een @cds.persistence.skip remote-entiteit worden niet
    //  automatisch geserveerd; we sturen de query door naar TripPin)
    this.on('READ', 'Employees', (req) => trippin.run(req.query));
    this.on('READ', 'Airlines', (req) => trippin.run(req.query));
    this.on('READ', 'Airports', (req) => trippin.run(req.query));

    // --- Employees: ProjectCode + afdeling uit EmployeeExtension toevoegen ---
    this.after('READ', 'Employees', async (rows) => {
      const list = toArray(rows);
      if (!list.length) return;
      const ext = await SELECT.from(EmployeeExtension)
        .where({ UserName: { in: list.map((r) => r.UserName) } });
      const byKey = index(ext, 'UserName');
      for (const r of list) {
        const x = byKey[r.UserName];
        if (x) {
          r.PrimePathProjectCode = x.PrimePathProjectCode;
          r.Department = x.Department;
        }
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
        const d = details.get(r.TripId);
        if (!d) continue;
        r.Owner = d.Owner;
        r.Name = d.Name;
        r.Description = d.Description;
        r.StartsAt = d.StartsAt;
        r.EndsAt = d.EndsAt;
        // val terug op TripPin-budget als er lokaal (nog) geen budget gezet is
        if (r.Budget == null && d.Budget != null) r.Budget = d.Budget;
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

/**
 * Haalt alle TripPin-reisdetails op (People $expand=Trips) en bouwt een
 * Map TripId -> { Owner, Name, Description, StartsAt, EndsAt, Budget }.
 * TripPin heeft geen top-level /Trips set, dus we lopen via People.
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
      if (map.has(t.TripId)) continue; // gedeelde trip: eerste eigenaar wint
      map.set(t.TripId, {
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
