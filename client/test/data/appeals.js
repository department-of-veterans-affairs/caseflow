import { hearingDateOptions } from './hearings';

export const defaultAssignHearing = {
  regionalOffice: null,
  hearingLocation: null,
  hearingDay: null,
  scheduledTimeString: null,
  errorMessages: {
    hearingDay: null,
    hearingLocation: null,
    scheduledTimeString: null,
    hasErrorMessages: false
  },
  apiFormattedValues: {
    scheduled_time_string: null,
    hearing_day_id: null,
    hearing_location: null
  }
};

export const powerOfAttorney = {
  representative_type: 'Attorney',
  representative_name: 'Clarence Darrow',
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
};

export const veteranInfo = {
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
};

export const appealData = {
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
  completedHearingOnPreviousAppeal: false,
  issues: [],
  decisionIssues: [
    {
      id: 1,
      description: 'This is a description of the decision'
    }, {
      id: 2,
      description: 'This is a description of another decision'
    }
  ],
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
  closestRegionalOfficeLabel: null,
  availableHearingLocations: [],
  status: 'not_distributed',
  decisionDate: null,
  nodDate: '2020-08-05',
  certificationDate: null,
  regionalOffice: null,
  caseflowVeteranId: 541,
  documentID: null,
  caseReviewId: null,
  canEditDocumentId: false,
  veteranDateOfDeath: null,
  attorneyCaseRewriteDetails: {
    note_from_attorney: null,
    untimely_evidence: null
  },
  veteranInfo: {
    ...veteranInfo
  },
  readableHearingRequestType: 'Video',
  readableOriginalHearingRequestType: 'Video',
  appellantTz: 'America/New_York'
};

export const amaAppeal = {
  ...appealData,
  id: '541',
  externalId: '2afefa82-5736-47c8-a977-0b4b8586f73e',
  hearings: [],
};

export const legacyAppeal = {
  ...appealData,
  id: '1',
  externalId: '1234456',
  docketName: 'Legacy',
  hearings: [],
  isLegacyAppeal: true
};

export const legacyAppealForTravelBoard = {
  ...legacyAppeal,
  closestRegionalOfficeLabel: 'Nashville Regional office',
  powerOfAttorney: {
    ...powerOfAttorney
  },
  readableHearingRequestType: 'Travel',
  readableOriginalHearingRequestType: 'Travel'
};

export const veteranInfoWithoutEmail = {
  veteranInfo: {
    veteran: {
      ...veteranInfo.veteran,
      email_address: null
    }
  }
};

export const openHearingAppeal = {
  ...appealData,
  id: '542',
  externalId: '3afefa82-5736-47c8-a977-0b4b8586f73e',
  hearings: [
    {
      heldBy: '',
      viewedByJudge: false,
      date: '2020-08-07T03:30:00.000-04:00',
      type: 'Central',
      externalId: '29e88a5d-8f00-47ea-b178-95a01d912b96',
      disposition: null,
      isVirtual: false,
      createdAt: '2020-04-07T03:30:00.000-04:00'
    }
  ],
};

export const scheduleHearingDetails = {
  regionalOffice: {
    key: 'RO17',
    alternate_locations: [
      'vba_317a', 'vc_0742V', 'vba_317'
    ],
    city: 'St. Petersburg',
    facility_locator_id: 'vba_317',
    hold_hearings: true,
    label: 'St. Petersburg regional office',
    state: 'FL',
    timezone: 'America/New_York',
  },
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
  hearingDay: hearingDateOptions[1].value,
  errorMessages: {
    hearingDay: null,
    hearingLocation: null,
    scheduledTimeString: null,
    hasErrorMessages: false
  },
  notes: '',
  apiFormattedValues: {
    scheduled_time_string: '08:45',
    hearing_day_id: 36,
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
};

export const amaAppealHearingData = {
  heldBy: 'Stacy Yellow',
  viewedByJudge: false,
  date: '2020-08-07T03:30:00.000-04:00',
  createdAt: '2020-04-07T03:30:00.000-04:00',
  type: 'Central',
  externalId: '29e88a5d-8f00-47ea-b178-95a01d912b96',
  disposition: null,
  isVirtual: false
};
