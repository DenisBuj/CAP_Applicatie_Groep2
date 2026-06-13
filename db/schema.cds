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
      trips      : Association to many TripExtension on trips.Owner = UserName;
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
