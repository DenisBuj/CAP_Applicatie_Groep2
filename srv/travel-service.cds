using { TripPinService as trippin } from './external/TripPinService';
using { primepath } from '../db/schema';

//
// TravelService — de mashup-laag.
//
// Leesbare/verrijkte entiteiten (Explorer) combineren TripPin-data met de
// lokale HANA-extensies. De verrijking gebeurt in srv/travel-service.js.
//
// Bronnen:
//   * Employees   -> lokale People-replica + EmployeeExtension (join via ext)
//   * Trips       -> lokale Trips-replica + Flights-associatie (FR-006/007)
//   * Flights     -> lokale Flights-replica (gevuld via replicateFlights bij boot)
//   * Airlines    -> REMOTE TripPin-service + AirlineExtension (PreferredVendor,
//                    FlightCount berekend in after-handler)
//   * Airports    -> REMOTE TripPin-service (puur read-only, geen extensie)
//
service TravelService @(path: '/travel') {

  // ---------------------------------------------------------------------------
  // READ / MERGED — Explorer (read-only)
  // ---------------------------------------------------------------------------

  /**
   * Medewerkers: lokale People-replica + EmployeeExtension (PrimePathProjectCode).
   * Lokaal gebaseerd, dus Projectcode is een echte (filterbare) kolom
   * en de reisgeschiedenis-associatie werkt op DB-niveau.
   */
  @readonly
  entity Employees as projection on primepath.People {
    key UserName,
        FirstName,
        LastName,
        MiddleName,
        Gender,
        Age,
        ext.PrimePathProjectCode as PrimePathProjectCode,
        // drill-down: de reizen van deze medewerker (reisgeschiedenis)
        trips                    as Trips : redirected to Trips
  };

  /**
   * Reizen: gebaseerd op de lokale Trips-replica (gevuld bij boot via replicateTrips).
   * Alle kolommen zijn echte DB-velden → filteren op StartsAt/EndsAt/Status werkt
   * op DB-niveau (FR-002, FR-006). Flights-associatie voor drill-down naar vluchten
   * per reis (FR-007). StatusCriticality is virtual (berekend in handler).
   */
  @readonly
  entity Trips as projection on primepath.Trips {
    key Owner,
    key TripId,
        Name,
        Description,
        StartsAt,
        EndsAt,
        Budget,
        Status,
        CostCenter,
        // 1=neutraal (Gepland), 2=oranje (Onderweg), 3=groen (Afgerond)
        virtual null as StatusCriticality : Integer,
        // drill-down terug naar de medewerker
        Employee : Association to one Employees on Employee.UserName = Owner,
        // drill-down naar de vluchten van deze reis (FR-007)
        Flights  : Association to many Flights
                     on Flights.Owner = Owner and Flights.TripId = TripId
  };

  /**
   * Vluchten: lokale replica van TripPin PlanItems/Flights (via replicateFlights).
   * Bevat AirlineCode, FromAirport, ToAirport als ICAO/codes + navigaties
   * naar Airlines en Airports voor drill-down (FR-007).
   */
  @readonly
  entity Flights as projection on primepath.Flights {
    key Owner,
    key TripId,
    key PlanItemId,
        FlightNumber,
        AirlineCode,
        AirlineName,
        FromAirport,
        FromAirportName,
        ToAirport,
        ToAirportName,
        StartsAt,
        EndsAt,
        // navigaties voor drill-down (TA §4: associaties naar Airline en Airport)
        Airline          : Association to one Airlines
                             on Airline.AirlineCode = AirlineCode,
        DepartureAirport : Association to one Airports
                             on DepartureAirport.IcaoCode = FromAirport,
        ArrivalAirport   : Association to one Airports
                             on ArrivalAirport.IcaoCode = ToAirport
  };

  /**
   * Airlines: TripPin Airlines + AirlineExtension (PreferredVendor) +
   * FlightCount berekend uit lokale Flights-tabel (FR-009).
   */
  @readonly
  entity Airlines as projection on trippin.Airlines {
    key AirlineCode,
        Name,
        virtual false as PreferredVendor : Boolean,
        virtual 0     as FlightCount     : Integer
  };

  /**
   * Airports: uitsluitend TripPin (geen verrijking).
   * NB: TripPin's `Location` is een genest complex-type dat CAP uitplat naar
   * Location_Address/Location_City_* — die platte namen bestaan niet op de remote
   * en breken de $select-delegatie (502). Bewust weggelaten in de MVP; geneste
   * Location-ondersteuning is een follow-up.
   */
  @readonly
  entity Airports as projection on trippin.Airports {
    key IcaoCode,
        IataCode,
        Name
  };

  // ---------------------------------------------------------------------------
  // KPI-functies (FR-001) — berekend in custom handler (srv/travel-service.js)
  // ---------------------------------------------------------------------------

  /** Meest gebruikte airlines op basis van aantal vluchten (FR-001, FR-009). */
  type TopAirline {
    AirlineCode : String(3);
    Name        : String;
    FlightCount : Integer;
  }

  /** Totaal aantal reizen in het systeem. */
  function TotalTrips() returns Integer;

  /**
   * Aantal medewerkers momenteel op reis:
   * StartsAt ≤ vandaag ≤ EndsAt (FA FR-001).
   */
  function TravelersNow() returns Integer;

  /**
   * Top-airlines gesorteerd op aantal vluchten (bewuste keuze boven budget,
   * FA FR-001 / FR-009).
   */
  function TopAirlines() returns many TopAirline;

  /**
   * KPI-overzicht voor HR/Admin (FR-001). OData singleton: bereikbaar via
   * GET /travel/KPISummary zonder sleutel in de URL.
   * TotalTrips   = totaal aantal reizen in het systeem.
   * TravelersNow = unieke medewerkers die momenteel op reis zijn.
   * TopAirlines  = zichtbaar in de Airlines-lijst (gesorteerd op FlightCount).
   * @cds.persistence.skip = geen DB-tabel; volledig in-memory berekend.
   */
  @readonly
  @(odata.singleton)
  @cds.persistence.skip
  entity KPISummary {
    TotalTrips   : Integer;
    TravelersNow : Integer;
  }

  // ---------------------------------------------------------------------------
  // WRITE — verrijkingstabellen (PrimePath-velden). CRUD-doelen voor de UI.
  // MVP: geen rolafdwinging — iedereen kan de extensievelden bewerken
  // (RBAC via XSUAA is een toekomstige uitbreiding, zie analyses).
  // ---------------------------------------------------------------------------
  @odata.draft.enabled
  entity EmployeeExtensions as projection on primepath.EmployeeExtension;

  @odata.draft.enabled
  entity TripExtensions as projection on primepath.TripExtension;

  @odata.draft.enabled
  entity AirlineExtensions as projection on primepath.AirlineExtension;
}
