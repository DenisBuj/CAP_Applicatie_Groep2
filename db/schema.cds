namespace primepath;

using { managed } from '@sap/cds/common';

//
// PrimePath HANA-verrijkingen bovenop de TripPin OData-data.
//
// Elke entiteit gebruikt dezelfde key als de bijbehorende TripPin-entiteit,
// zodat ze in de mashup-service (FASE 3) 1-op-1 gekoppeld kunnen worden.
// `managed` voegt createdAt/By + modifiedAt/By toe — handig om bij te houden
// wie (Travel Coördinator) status/kostenplaats/vendor/projectcode heeft aangepast.
// HR/Admin is uitsluitend read-only (zie Functionele Analyse §3).
//

/** Reisstatus — beheerd door de Travel Coördinator (FR-008); HR/Admin is read-only. */
type TripStatus : String enum {
  Gepland;
  Onderweg;
  Afgerond;
}

/**
 * Verrijking voor TripPin `People`.
 * Key = UserName (TripPin Person.UserName).
 * Enkel PrimePathProjectCode — de overige medewerkervelden komen uit TripPin.
 */
entity EmployeeExtension : managed {
  key UserName              : String(255);
      PrimePathProjectCode  : String(40);
}

/**
 * Lokale replica van TripPin `People` — bij het opstarten gevuld vanuit de
 * remote service (zie srv/travel-service.js). Lokaal nodig omdat associaties,
 * joins en aggregaties tussen remote- en lokale data niet werken op DB-niveau.
 * Combineert via associaties met de verrijking en de reizen.
 */
entity People {
  key UserName   : String(255);
      FirstName  : String;
      LastName   : String;
      MiddleName : String;
      Gender     : String;
      Age        : Integer;
      ext        : Association to one EmployeeExtension on ext.UserName = UserName;
      trips      : Association to many Trips on trips.Owner = UserName;
}

/**
 * Lokale replica van TripPin PlanItems/Flights, geaggregeerd via People
 * $expand=Trips/PlanItems (zie srv/travel-service.js: replicateFlights).
 * Samengestelde sleutel Owner + TripId + PlanItemId.
 * Bevat alleen vluchten (gefilterd op @odata.type = Flight) voor FR-007/FR-009.
 */
entity Flights {
  key Owner           : String(255);
  key TripId          : Integer;
  key PlanItemId      : Integer;
      FlightNumber    : String(10);
      AirlineCode     : String(3);
      AirlineName     : String(100);  // naam van de airline (uit TripPin bij replicatie)
      FromAirport     : String(4);    // ICAO-code vertrekhaven
      FromAirportName : String(100);  // naam van de vertrekhaven (uit TripPin)
      ToAirport       : String(4);    // ICAO-code aankomstluchthaven
      ToAirportName   : String(100);  // naam van de aankomstluchthaven (uit TripPin)
      StartsAt        : DateTime;
      EndsAt          : DateTime;
}

/**
 * Lokale replica van alle TripPin-reizen, geaggregeerd via People $expand=Trips
 * (zie srv/travel-service.js: replicateTrips). Bevat echte kolommen zodat
 * filteren en sorteren op periode op DB-niveau werken (FR-002, FR-006).
 * Status en CostCenter worden samengevoegd vanuit TripExtension bij replicatie;
 * reizen zonder extensie krijgen Status='Gepland' en lege CostCenter.
 */
entity Trips {
  key Owner       : String(255);
  key TripId      : Integer;
      Name        : String;
      Description : String;
      StartsAt    : DateTime;
      EndsAt      : DateTime;
      Budget      : Decimal(15, 2);
      Status      : TripStatus default #Gepland;
      CostCenter  : String(40);
}

/**
 * Verrijking voor TripPin `Trips` (alleen bereikbaar via People/Trips).
 * Samengestelde key Owner + TripId: een TripPin TripId is niet gegarandeerd
 * uniek over personen heen bij gedeelde trips, daarom hoort de Owner (= UserName)
 * mee in de sleutel (zie finale Technische Analyse).
 * Budget komt read-only uit TripPin; hier bewaren we enkel Status + CostCenter.
 */
entity TripExtension : managed {
  key Owner      : String(255);
  key TripId     : Integer;
      Status     : TripStatus default #Gepland;
      CostCenter : String(40);
}

/**
 * Verrijking voor TripPin `Airlines`.
 * Key = AirlineCode (TripPin Airline.AirlineCode).
 */
entity AirlineExtension : managed {
  key AirlineCode     : String(3);
      PreferredVendor  : Boolean default false;
}
