using { TravelService } from '../../../srv/travel-service';

// ============================================================================
// Employees  (TripPin People + EmployeeExtension)
// ============================================================================
annotate TravelService.Employees with @(
  UI: {
    HeaderInfo: {
      $Type          : 'UI.HeaderInfoType',
      TypeName       : 'Medewerker',
      TypeNamePlural : 'Medewerkers',
      Title          : { $Type: 'UI.DataField', Value: FirstName },
      Description    : { $Type: 'UI.DataField', Value: UserName }
    },
    // FR-003/FR-004: zoeken op naam + projectcode + filteren op beschikbaarheid/planning
    SelectionFields : [ FirstName, LastName, PrimePathProjectCode, IsTraveling, HasPlannedTrip ],
    LineItem : [
      { $Type: 'UI.DataField', Value: UserName,             Label: 'Gebruikersnaam' },
      { $Type: 'UI.DataField', Value: FirstName,            Label: 'Voornaam' },
      { $Type: 'UI.DataField', Value: LastName,             Label: 'Achternaam' },
      // Beschikbaarheid: gekleurd (oranje "Op reis" / groen "Beschikbaar") — voor inplannen
      { $Type: 'UI.DataField', Value: Availability,         Label: 'Beschikbaarheid', Criticality: AvailabilityCriticality },
      // Geplande reis: "Gepland" of "—" — direct overzicht wie al ingepland is
      { $Type: 'UI.DataField', Value: PlannedLabel,         Label: 'Geplande reis' },
      { $Type: 'UI.DataField', Value: PrimePathProjectCode, Label: 'Projectcode' }
    ],
    // ---- Object Page ----
    Facets : [
      { $Type: 'UI.ReferenceFacet', ID: 'GegevensFacet',
        Label: 'Gegevens',          Target: '@UI.FieldGroup#Details' },
      // Planning: enkel de GEPLANDE reizen — waar & wanneer iemand ingepland is.
      { $Type: 'UI.ReferenceFacet', ID: 'GeplandeReizenFacet',
        Label: 'Geplande reizen',   Target: 'PlannedTrips/@UI.PresentationVariant' },
      // FR-004: volledige reisgeschiedenis + geplande trips, chronologisch gesorteerd.
      // Doel = de PresentationVariant van Trips (SortOrder op StartsAt), zodat de
      // ingebedde tabel echt chronologisch laadt i.p.v. in willekeurige DB-volgorde.
      { $Type: 'UI.ReferenceFacet', ID: 'ReizenFacet',
        Label: 'Reisgeschiedenis',  Target: 'Trips/@UI.PresentationVariant' }
    ],
    FieldGroup #Details : {
      Data : [
        { $Type: 'UI.DataField', Value: UserName,             Label: 'Gebruikersnaam' },
        { $Type: 'UI.DataField', Value: FirstName,            Label: 'Voornaam' },
        { $Type: 'UI.DataField', Value: LastName,             Label: 'Achternaam' },
        { $Type: 'UI.DataField', Value: Gender,               Label: 'Geslacht' },
        { $Type: 'UI.DataField', Value: Age,                  Label: 'Leeftijd' },
        { $Type: 'UI.DataField', Value: Availability,         Label: 'Beschikbaarheid', Criticality: AvailabilityCriticality },
        { $Type: 'UI.DataField', Value: PlannedLabel,         Label: 'Geplande reis' },
        { $Type: 'UI.DataField', Value: PrimePathProjectCode, Label: 'Projectcode' }
      ]
    },
    // FR-005: projectcode beheren rechtstreeks op het profiel (knop op de Object Page).
    Identification : [
      { $Type : 'UI.DataFieldForAction',
        Action: 'TravelService.setProjectCode',
        Label : 'Projectcode bijwerken' }
    ]
  }
) {
  UserName             @title: 'Gebruikersnaam';
  FirstName            @title: 'Voornaam';
  LastName             @title: 'Achternaam';
  MiddleName           @title: 'Tweede naam';
  Gender               @title: 'Geslacht';
  Age                  @title: 'Leeftijd';
  IsTraveling          @title: 'Op reis';
  Availability         @title: 'Beschikbaarheid';
  HasPlannedTrip       @title: 'Geplande reis';
  PlannedLabel         @title: 'Geplande reis';
  PrimePathProjectCode @title: 'Projectcode';
};

// ============================================================================
// EmployeeExtensions  (draft editing: PrimePathProjectCode)  FR-005
// ============================================================================
annotate TravelService.EmployeeExtensions with @(
  UI: {
    HeaderInfo: {
      $Type          : 'UI.HeaderInfoType',
      TypeName       : 'Medewerkerextensie',
      TypeNamePlural : 'Medewerkerextensies',
      Title          : { $Type: 'UI.DataField', Value: UserName },
      Description    : { $Type: 'UI.DataField', Value: PrimePathProjectCode }
    },
    LineItem : [
      { $Type: 'UI.DataField', Value: UserName,             Label: 'Gebruikersnaam' },
      { $Type: 'UI.DataField', Value: PrimePathProjectCode, Label: 'Projectcode' }
    ],
    Facets : [
      { $Type: 'UI.ReferenceFacet', ID: 'EditFacet',
        Label: 'Projectgegevens', Target: '@UI.FieldGroup#EditFields' }
    ],
    // FR-005: Team Lead stelt projectcode in per medewerker
    FieldGroup #EditFields : {
      Data : [
        { $Type: 'UI.DataField', Value: UserName,             Label: 'Gebruikersnaam' },
        { $Type: 'UI.DataField', Value: PrimePathProjectCode, Label: 'Projectcode' }
      ]
    }
  }
) {
  UserName             @title: 'Gebruikersnaam'  @readonly;
  PrimePathProjectCode @title: 'Projectcode';
};
