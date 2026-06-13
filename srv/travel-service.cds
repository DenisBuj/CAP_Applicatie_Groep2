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
//   * Trips       -> lokale Trips-replica (gevuld via replicateTrips bij boot),
//                    Status/CostCenter al samengevoegd; filteren/sorteren op
//                    periode en status werken volledig op DB-niveau.
//   * Airlines    -> REMOTE TripPin-service, verrijkt met AirlineExtension.
//   * Airports    -> REMOTE TripPin-service (puur read-only, geen extensie).
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
   * op DB-niveau (FR-002, FR-006). StatusCriticality is virtual (berekend in handler).
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
        Employee : Association to one Employees on Employee.UserName = Owner
  };

  /** Airlines: TripPin Airlines + AirlineExtension (PreferredVendor). */
  @readonly
  entity Airlines as projection on trippin.Airlines {
    key AirlineCode,
        Name,
        virtual false as PreferredVendor : Boolean
  };

  /** Airports: uitsluitend TripPin (geen verrijking). */
  @readonly
  entity Airports as projection on trippin.Airports {
    key IcaoCode,
        IataCode,
        Name,
        Location
  };

  // ---------------------------------------------------------------------------
  // WRITE — verrijkingstabellen (PrimePath-velden). CRUD-doelen voor de UI.
  // MVP: geen rolafdwinging — iedereen kan de extensievelden bewerken
  // (RBAC via XSUAA is een toekomstige uitbreiding, zie analyses).
  // ---------------------------------------------------------------------------
  entity EmployeeExtensions as projection on primepath.EmployeeExtension;

  entity TripExtensions as projection on primepath.TripExtension;

  entity AirlineExtensions as projection on primepath.AirlineExtension;
}
