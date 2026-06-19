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
  key UserName    : String(255);
      FirstName   : String;
      LastName    : String;
      MiddleName  : String;
      Gender      : String;
      Age         : Integer;
      // Beschikbaarheid/planning voor de Team Lead — afgeleid uit de Trips bij
      // replicatie en bijgewerkt bij elke statuswijziging. Echte kolommen zodat ze
      // filterbaar/sorteerbaar zijn en niet van $select afhangen.
      IsTraveling             : Boolean default false;  // heeft een 'Onderweg'-reis
      HasPlannedTrip          : Boolean default false;  // heeft een 'Gepland'-reis
      Availability            : String(20);             // "Op reis" / "Beschikbaar"
      AvailabilityCriticality : Integer;                // 2 = oranje, 3 = groen
      PlannedLabel            : String(20);             // "Gepland" / "—"
      ext         : Association to one EmployeeExtension on ext.UserName = UserName;
      trips       : Association to many Trips on trips.Owner = UserName;
      // enkel de geplande reizen (status 'Gepland') — planningssectie Team Lead
      plannedTrips: Association to many Trips on plannedTrips.Owner = UserName
                                             and plannedTrips.Status = 'Gepland';
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
      FromCountry     : String(100);  // land van de vertrekhaven (TripPin Location.City.CountryRegion)
      ToAirport       : String(4);    // ICAO-code aankomstluchthaven
      ToAirportName   : String(100);  // naam van de aankomstluchthaven (uit TripPin)
      ToCountry       : String(100);  // land van de aankomstluchthaven (TripPin Location.City.CountryRegion)
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
      // FR-002: projectcode van de reizende medewerker, mee gerepliceerd vanuit
      // EmployeeExtension zodat reizen op DB-niveau op projectcode filterbaar zijn.
      ProjectCode : String(40);
      // Bestemming afgeleid uit de vluchten (aankomstluchthaven van de laatste vlucht),
      // zodat de coördinator op land/luchthaven kan filteren ("wie reist naar de VS
      // en via welke luchthaven?"). Gevuld na de Flights-replicatie.
      DestinationCountry : String(100);
      DestinationAirport : String(100);
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
