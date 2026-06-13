using { TripPinService as trippin } from './external/TripPinService';
using { primepath } from '../db/schema';

//
// TravelService — de mashup-laag.
//
// Leesbare/verrijkte entiteiten (Explorer) combineren TripPin-data met de
// lokale HANA-extensies. De verrijking gebeurt in srv/travel-service.js.
//
// Twee soorten bronnen:
//   * Employees / Airlines / Airports  -> projectie op de REMOTE TripPin-service
//                                          (CAP delegeert de READ naar TripPin),
//                                          verrijkt via after-READ handler.
//   * Trips                            -> projectie op de LOKALE TripExtension
//                                          (zodat filteren op Status/Budget op DB
//                                          gebeurt), verrijkt met TripPin-details.
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

  /** Reizen: lokaal beheerde Status/CostCenter + TripPin reisdetails (naam, data, budget). */
  @readonly
  entity Trips as projection on primepath.TripExtension {
    key Owner,
    key TripId,
        Status,
        CostCenter,
        // verrijking uit TripPin (gevuld in after-READ):
        virtual null as Name             : String,
        virtual null as Description      : String,
        virtual null as StartsAt         : DateTime,
        virtual null as EndsAt           : DateTime,
        virtual null as Budget           : Decimal(15, 2),
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
