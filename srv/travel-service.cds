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

  /** Medewerkers: TripPin People + EmployeeExtension (ProjectCode, afdeling). */
  @readonly
  @(restrict: [{ grant: 'READ', to: ['TravelCoordinator', 'TeamLead', 'HRAdmin'] }])
  entity Employees as projection on trippin.People {
    key UserName,
        FirstName,
        LastName,
        MiddleName,
        Gender,
        Age,
        Emails,
        // verrijking (gevuld in after-READ):
        virtual null as PrimePathProjectCode : String(40),
        virtual null as Department           : String(80)
  };

  /** Reizen: lokaal beheerde Status/Budget + TripPin reisdetails (eigenaar, naam, data). */
  @readonly
  @(restrict: [{ grant: 'READ', to: ['TravelCoordinator', 'TeamLead', 'HRAdmin'] }])
  entity Trips as projection on primepath.TripExtension {
    key TripId,
        Status,
        Budget,
        // verrijking uit TripPin (gevuld in after-READ):
        virtual null as Owner       : String(255),
        virtual null as Name        : String,
        virtual null as Description : String,
        virtual null as StartsAt    : DateTime,
        virtual null as EndsAt      : DateTime
  };

  /** Airlines: TripPin Airlines + AirlineExtension (PreferredVendor). */
  @readonly
  @(restrict: [{ grant: 'READ', to: ['TravelCoordinator', 'TeamLead', 'HRAdmin'] }])
  entity Airlines as projection on trippin.Airlines {
    key AirlineCode,
        Name,
        virtual false as PreferredVendor : Boolean
  };

  /** Airports: uitsluitend TripPin (geen verrijking). */
  @readonly
  @(restrict: [{ grant: 'READ', to: ['TravelCoordinator', 'TeamLead', 'HRAdmin'] }])
  entity Airports as projection on trippin.Airports {
    key IcaoCode,
        IataCode,
        Name
  };

  // ---------------------------------------------------------------------------
  // WRITE — Admin (verrijkingstabellen). Volledige CRUD uitsluitend voor HRAdmin.
  // ---------------------------------------------------------------------------
  @(restrict: [{ grant: '*', to: 'HRAdmin' }])
  entity EmployeeExtensions as projection on primepath.EmployeeExtension;

  @(restrict: [{ grant: '*', to: 'HRAdmin' }])
  entity TripExtensions as projection on primepath.TripExtension;

  @(restrict: [{ grant: '*', to: 'HRAdmin' }])
  entity AirlineExtensions as projection on primepath.AirlineExtension;
}
