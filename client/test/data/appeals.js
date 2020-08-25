export const amaAppeal = {
  id: '541',
  externalId: '3afefa82-5736-47c8-a977-0b4b8586f73e',
  docketName: 'hearing',
  withdrawn: false,
  removed: false,
  overtime: false,
  isLegacyAppeal: false,
  caseType: 'Original',
  isAdvancedOnDocket: false,
  issueCount: 0,
  docketNumber: '200805-541',
  assignedAttorney: null,
  assignedJudge: null,
  veteranFullName: 'Abellona Valtas',
  veteranFileNumber: '123456789',
  isPaperCase: false,
  vacateType: null,
  hearings: [
    {
      heldBy: '',
      viewedByJudge: false,
      date: '2020-08-07T03:30:00.000-04:00',
      type: 'Central',
      externalId: '29e88a5d-8f00-47ea-b178-95a01d912b96',
      disposition: null,
      isVirtual: false
    }
  ],
  completedHearingOnPreviousAppeal: false,
  issues: [],
  decisionIssues: [],
  canEditRequestIssues: false,
  appellantIsNotVeteran: false,
  appellantFullName: 'Abellona Valtas',
  appellantAddress: {
    address_line_1: '9999 MISSION ST',
    address_line_2: 'UBER',
    address_line_3: 'APT 2',
    city: 'SAN FRANCISCO',
    zip: '94103',
    country: 'USA',
    state: 'CA'
  },
  appellantRelationship: 'Spouse',
  assignedToLocation: 'Hearing Admin',
  closestRegionalOffice: null,
  availableHearingLocations: [],
  status: 'not_distributed',
  decisionDate: null,
  nodDate: '2020-08-05',
  certificationDate: null,
  powerOfAttorney: {
    representative_type: 'Attorney',
    representative_name: 'Attorney McAttorneyFace',
    representative_address: {
      address_line_1: '9999 MISSION ST',
      address_line_2: 'UBER',
      address_line_3: 'APT 2',
      city: 'SAN FRANCISCO',
      zip: '94103',
      country: 'USA',
      state: 'CA'
    },
    representative_email_address: 'tom.brady@caseflow.gov'
  },
  regionalOffice: null,
  caseflowVeteranId: 541,
  documentID: null,
  caseReviewId: null,
  canEditDocumentId: false,
  attorneyCaseRewriteDetails: {
    note_from_attorney: null,
    untimely_evidence: null
  },
  veteranInfo: {
    veteran: {
      full_name: 'Abellona Valtas',
      gender: 'M',
      date_of_birth: '01/10/1935',
      date_of_death: null,
      email_address: 'Abellona.Valtas@test.com',
      address: {
        address_line_1: '1234 Main Street',
        address_line_2: null,
        address_line_3: null,
        city: 'Orlando',
        state: 'FL',
        zip: '12345',
        country: 'USA'
      }
    }
  }
}
;

export const scheduleHearingDetails = {
  regionalOffice: 'RO17',
  hearingLocation: {
    name: 'Holdrege VA Clinic',
    address: '1118 Burlington Street, Holdrege NE 68949-1705',
    city: 'Holdrege',
    state: 'NE',
    zipCode: '68949-1705',
    distance: 0,
    classification: 'Primary Care CBOC',
    facilityId: 'vba_317a',
    facilityType: 'va_health_facility'
  },
  scheduledTimeString: '08:45',
  hearingDay: {
    hearingId: 11,
    regionalOffice: 'RO17',
    timezone: 'America/New_York',
    scheduledFor: '2020-08-17',
    requestType: 'V',
    room: '1',
    roomLabel: '1 (1W200A)',
    filledSlots: 2,
    totalSlots: 12,
    hearingDate: '2020-08-17'
  },
  errorMessages: {
    hearingDay: null,
    hearingLocation: null,
    scheduledTimeString: null,
    hasErrorMessages: false
  },
  apiFormattedValues: {
    scheduled_time_string: '08:45',
    hearing_day_id: 11,
    hearing_location: {
      name: 'Holdrege VA Clinic',
      address: '1118 Burlington Street, Holdrege NE 68949-1705',
      city: 'Holdrege',
      state: 'NE',
      zip_code: '68949-1705',
      distance: 0,
      classification: 'Primary Care CBOC',
      facility_id: 'vba_317a',
      facility_type: 'va_health_facility'
    }
  }
}
;
