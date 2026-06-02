/* checksum : 1fcab69551bfb5a294499dfe000b3a59 */
@cds.external : true
service TripPinService {
  @cds.external : true
  function GetPersonWithMostFriends() returns People;

  @cds.external : true
  function GetNearestAirport(
    lat : Double not null,
    lon : Double not null
  ) returns Airports;

  @cds.external : true
  action ResetDataSource();

  @cds.external : true
  @cds.persistence.skip : true
  entity Trip {
    key TripId : Integer not null;
    ShareId : UUID not null;
    Name : String;
    @odata.Type : 'Edm.Single'
    Budget : Double not null;
    Description : String;
    Tags : many String;
    @odata.Precision : 0
    @odata.Type : 'Edm.DateTimeOffset'
    StartsAt : DateTime not null;
    @odata.Precision : 0
    @odata.Type : 'Edm.DateTimeOffset'
    EndsAt : DateTime not null;
    PlanItems : Association to many PlanItem {  };
  } actions {
    function GetInvolvedPeople() returns many People;
  };

  @cds.external : true
  @cds.persistence.skip : true
  @open : true
  entity PlanItem {
    key PlanItemId : Integer not null;
    ConfirmationCode : String;
    @odata.Precision : 0
    @odata.Type : 'Edm.DateTimeOffset'
    StartsAt : DateTime not null;
    @odata.Precision : 0
    @odata.Type : 'Edm.DateTimeOffset'
    EndsAt : DateTime not null;
    @odata.Type : 'Edm.Duration'
    Duration : String not null;
  };

  @cds.external : true
  @cds.persistence.skip : true
  entity Event : PlanItem {
    OccursAt : EventLocation;
    Description : String;
  };

  @cds.external : true
  @cds.persistence.skip : true
  @open : true
  entity PublicTransportation : PlanItem {
    SeatNumber : String;
  };

  @cds.external : true
  @cds.persistence.skip : true
  entity Flight : PublicTransportation {
    FlightNumber : String;
    Airline : Association to one Airlines {  };
    ![From] : Association to one Airports {  };
    To : Association to one Airports {  };
  };

  @cds.external : true
  @cds.persistence.skip : true
  entity Employee : People {
    Cost : Integer64 not null;
    Peers : Association to many People {  };
  };

  @cds.external : true
  @cds.persistence.skip : true
  entity Manager : People {
    Budget : Integer64 not null;
    BossOffice : Location;
    DirectReports : Association to many People {  };
  };

  @cds.external : true
  @open : true
  type Location {
    Address : String;
    City : City;
  };

  @cds.external : true
  type City {
    Name : String;
    CountryRegion : String;
    Region : String;
  };

  @cds.external : true
  type AirportLocation : Location {
    @odata.Type : 'Edm.GeographyPoint'
    Loc : String;
  };

  @cds.external : true
  type EventLocation : Location {
    BuildingInfo : String;
  };

  @cds.external : true
  type PersonGender : Integer enum {
    Male = 0;
    Female = 1;
    Unknown = 2;
  };

  @cds.external : true
  type Feature : Integer enum {
    Feature1 = 0;
    Feature2 = 1;
    Feature3 = 2;
    Feature4 = 3;
  };

  @cds.external : true
  @cds.persistence.skip : true
  @open : true
  entity People {
    key UserName : String not null;
    FirstName : String not null;
    LastName : String(26);
    MiddleName : String;
    Gender : PersonGender not null;
    Age : Integer64;
    Emails : many String;
    AddressInfo : many Location;
    HomeAddress : Location;
    FavoriteFeature : Feature not null;
    Features : many Feature not null;
    Friends : Association to many People {  };
    BestFriend : Association to one People {  };
    Trips : Association to many Trip {  };
  } actions {
    action UpdateLastName(
      lastName : String not null
    ) returns Boolean not null;
    action ShareTrip(
      userName : String not null,
      tripId : Integer not null
    );
    function GetFavoriteAirline() returns Airlines;
    function GetFriendsTrips(
      userName : String not null
    ) returns many Trip;
  };

  @cds.external : true
  @cds.persistence.skip : true
  entity Airlines {
    key AirlineCode : String not null;
    Name : String;
  };

  @cds.external : true
  @cds.persistence.skip : true
  entity Airports {
    Name : String;
    key IcaoCode : String not null;
    IataCode : String;
    Location : AirportLocation;
  };

  @cds.external : true
  @cds.persistence.skip : true
  @open : true
  @odata.singleton : true
  entity Me {
    key UserName : String not null;
    FirstName : String not null;
    LastName : String(26);
    MiddleName : String;
    Gender : PersonGender not null;
    Age : Integer64;
    Emails : many String;
    AddressInfo : many Location;
    HomeAddress : Location;
    FavoriteFeature : Feature not null;
    Features : many Feature not null;
    Friends : Association to many People {  };
    BestFriend : Association to one People {  };
    Trips : Association to many Trip {  };
  } actions {
    action UpdateLastName(
      lastName : String not null
    ) returns Boolean not null;
    action ShareTrip(
      userName : String not null,
      tripId : Integer not null
    );
    function GetFavoriteAirline() returns Airlines;
    function GetFriendsTrips(
      userName : String not null
    ) returns many Trip;
  };
};

