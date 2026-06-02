namespace primepath;

using { managed } from '@sap/cds/common';

//
// PrimePath HANA-verrijkingen bovenop de TripPin OData-data.
//
// Elke entiteit gebruikt dezelfde key als de bijbehorende TripPin-entiteit,
// zodat ze in de mashup-service (FASE 3) 1-op-1 gekoppeld kunnen worden.
// `managed` voegt createdAt/By + modifiedAt/By toe — handig om bij te houden
// wie (HRAdmin) budget/status/vendor heeft aangepast.
//

/** Reisstatus — beheerd door HR/Admin (FR-008). */
type TripStatus : String enum {
  Gepland;
  Onderweg;
  Afgerond;
}

/**
 * Verrijking voor TripPin `People`.
 * Key = UserName (TripPin Person.UserName).
 * `Department` is toegevoegd: TripPin Person kent geen afdeling, maar
 * FR-002/FR-003 vereisen filteren/zoeken op afdeling.
 */
entity EmployeeExtension : managed {
  key UserName              : String(255);
      PrimePathProjectCode  : String(40);
      Department            : String(80);
}

/**
 * Verrijking voor TripPin `Trips` (alleen bereikbaar via People/Trips).
 * Key = TripId (TripPin Trip.TripId, Edm.Int32 — globaal uniek).
 * NB: TripPin heeft zelf al een (read-only, float) Budget. Dit is het door
 * PrimePath beheerde budget (Decimal) dat in de mashup voorrang krijgt.
 */
entity TripExtension : managed {
  key TripId  : Integer;
      Status  : TripStatus default #Gepland;
      Budget  : Decimal(15, 2);
}

/**
 * Verrijking voor TripPin `Airlines`.
 * Key = AirlineCode (TripPin Airline.AirlineCode).
 */
entity AirlineExtension : managed {
  key AirlineCode     : String(3);
      PreferredVendor  : Boolean default false;
}
