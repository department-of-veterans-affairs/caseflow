/* eslint-disable max-lines */
import { times } from 'lodash';
import { scheduleHearingTask } from './tasks';
import moment from 'moment';
import regionalOfficesJsonResponse from './regionalOfficesJsonResponse';

export const virtualHearingEmails = {
  emailEvents: [
    {
      sentTo: 'POA/Representative Email',
      emailType: 'confirmation',
      emailAddress: 'tom.brady@caseflow.gov',
      sentAt: '2020-06-29T14:55:12.620-04:00',
      sentBy: 'BVASYELLOW',
    },
    {
      sentTo: 'Appellant Email',
      emailType: 'confirmation',
      emailAddress: 'Bob.Smith@test.com',
      sentAt: '2020-06-29T14:55:12.501-04:00',
      sentBy: 'BVASYELLOW',
    },
  ],
};

export const virtualHearing = {
  virtualHearing: {
    appellantTz: 'America/Denver',
    representativeTz: 'America/Los_Angeles',
    appellantEmail: 'Bob.Smith@test.com',
    representativeEmail: 'tom.brady@caseflow.gov',
    status: 'active',
    requestCancelled: false,
    clientHost: 'care.evn.va.gov',
    aliasWithHost: 'BVA0000009@care.evn.va.gov',
    hostPin: '8600030#',
    guestPin: '2684353125#',
    hostLink:
      'https://care.evn.va.gov/bva-app/?join=1&media=&escalate=1&conference=BVA0000009@care.evn.va.gov&pin=8600030#&role=host',
    guestLink:
      'https://care.evn.va.gov/bva-app/?join=1&media=&escalate=1&conference=BVA0000009@care.evn.va.gov&pin=2684353125#&role=guest',
    jobCompleted: true,
  },
};

export const amaHearing = {
  poaName: 'AMERICAN LEGION',
  currentIssueCount: 1,
  caseType: 'Original',
  aod: false,
  advanceOnDocketMotion: null,
  appealExternalId: '005334f7-b5c6-490c-a310-7dc5db22c8c3',
  appealId: 4,
  appellantAddressLine1: '9999 MISSION ST',
  appellantCity: 'SAN FRANCISCO',
  appellantEmailAddress: 'tom.brady@caseflow.gov',
  appellantFirstName: 'Bob',
  appellantIsNotVeteran: false,
  appellantLastName: 'Smith',
  appellantState: 'CA',
  appellantTz: 'America/Los_Angeles',
  appellantZip: '94103',
  availableHearingLocations: {},
  bvaPoc: null,
  centralOfficeTimeString: '03:30',
  claimantId: 4,
  closestRegionalOffice: null,
  disposition: null,
  dispositionEditable: true,
  docketName: 'hearing',
  docketNumber: '200628-4',
  evidenceWindowWaived: false,
  externalId: '9bb8e27e-9b89-48cd-8b0b-2e75cfa5627a',
  hearingDayId: 4,
  id: 4,
  judgeId: 3,
  judge: {
    id: 3,
    createdAt: '2020-06-25T11:00:43.257-04:00',
    cssId: 'BVAAABSHIRE',
    efolderDocumentsFetchedAt: null,
    email: null,
    fullName: 'Aaron Judge_HearingsAndCases Abshire',
    lastLoginAt: null,
    roles: {},
    selectedRegionalOffice: null,
    stationId: '101',
    status: 'active',
    statusUpdatedAt: null,
    updatedAt: '2020-06-25T11:00:43.257-04:00',
    displayName: 'BVAAABSHIRE (VACO)',
  },
  location: null,
  militaryService: '',
  notes: null,
  paperCase: false,
  prepped: null,
  readableLocation: 'Washington, DC',
  readableRequestType: 'Central',
  regionalOfficeKey: 'C',
  regionalOfficeName: 'Central',
  regionalOfficeTimezone: 'America/New_York',
  representative: 'Clarence Darrow',
  representativeName: 'PARALYZED VETERANS OF AMERICA, INC.',
  representativeEmailAddress: 'tom.brady@caseflow.gov',
  representativeTz: 'America/Denver',
  room: '2',
  scheduledFor: '2020-07-06T06:00:00.000-04:00',
  scheduledForIsPast: false,
  scheduledTime: '2000-01-01T03:30:00.000-05:00',
  scheduledTimeString: '03:30',
  summary: null,
  transcriptRequested: null,
  transcription: {},
  uuid: '9bb8e27e-9b89-48cd-8b0b-2e75cfa5627a',
  veteranAge: 85,
  veteranFileNumber: '500000003',
  veteranFirstName: 'Bob',
  veteranGender: 'M',
  veteranLastName: 'Smith',
  veteranEmailAddress: 'Bob.Smith@test.com',
  isVirtual: true,
  wasVirtual: false,
  witness: null,
  worksheetIssues: {},
  ...virtualHearing,
  ...virtualHearingEmails,
};

export const legacyHearing = {
  poaName: 'AMERICAN LEGION',
  currentIssueCount: 1,
  caseType: 'Original',
  aod: false,
  advanceOnDocketMotion: null,
  appealExternalId: '0bf0263c-d863-4405-9b2e-f55cff77c6c3',
  appealId: 613,
  appellantAddressLine1: '9999 MISSION ST',
  appellantCity: 'SAN FRANCISCO',
  appellantEmailAddress: 'tom.brady@caseflow.gov',
  appellantFirstName: 'Tom',
  appellantIsNotVeteran: true,
  appellantLastName: 'Brady',
  appellantState: 'CA',
  appellantZip: '94103',
  availableHearingLocations: {},
  bvaPoc: null,
  centralOfficeTimeString: '04:00',
  claimantId: 604,
  closestRegionalOffice: null,
  disposition: null,
  dispositionEditable: true,
  docketName: 'legacy',
  docketNumber: '200624-613',
  evidenceWindowWaived: false,
  externalId: '61e7af7a-586c-446d-b8ee-a65be467e9e0',
  hearingDayId: 11,
  id: 10,
  judge: {
    id: 3,
    createdAt: '2020-06-25T11:00:43.257-04:00',
    cssId: 'BVAAABSHIRE',
    efolderDocumentsFetchedAt: null,
    email: null,
    fullName: 'Aaron Judge_HearingsAndCases Abshire',
    lastLoginAt: null,
    roles: {},
    selectedRegionalOffice: null,
    stationId: '101',
    status: 'active',
    statusUpdatedAt: null,
    updatedAt: '2020-06-25T11:00:43.257-04:00',
    displayName: 'BVAAABSHIRE (VACO)',
  },
  judgeId: '3',
  location: null,
  militaryService: '',
  notes: null,
  paperCase: false,
  prepped: null,
  readableLocation: null,
  readableRequestType: 'Video',
  regionalOfficeKey: 'RO17',
  regionalOfficeName: 'St. Petersburg regional office',
  regionalOfficeTimezone: 'America/New_York',
  representative: 'PARALYZED VETERANS OF AMERICA, INC.',
  representativeName: null,
  representativeEmailAddress: 'tom.brady@caseflow.gov',
  room: '1',
  scheduledFor: '2020-07-06T04:00:00.000-04:00',
  scheduledForIsPast: false,
  scheduledTime: '2000-01-01T04:00:00.000-05:00',
  scheduledTimeString: '04:00',
  summary: null,
  uuid: '61e7af7a-586c-446d-b8ee-a65be467e9e0',
  veteranAge: 85,
  veteranFileNumber: '100000005',
  veteranFirstName: 'Brian',
  veteranGender: 'M',
  veteranLastName: 'Hodkiewicz',
  veteranEmailAddress: 'Brian.Hodkiewicz@test.com',
  isVirtual: false,
  virtualHearing: null,
  emailEvents: [],
  wasVirtual: false,
  witness: null,
  worksheetIssues: {},
};

export const defaultHearing = {
  caseType: 'Original',
  poaName: 'AMERICAN LEGION',
  aod: false,
  advanceOnDocketMotion: null,
  appealExternalId: '0bf0263c-d863-4405-9b2e-f55cff77c6c4',
  appealId: 613,
  appellantAddressLine1: '9999 MISSION ST',
  appellantCity: 'SAN FRANCISCO',
  appellantEmailAddress: 'tom.brady@caseflow.gov',
  appellantFirstName: 'Tom',
  appellantIsNotVeteran: false,
  appellantRelationship: 'Spouse',
  appellantLastName: 'Brady',
  appellantState: 'CA',
  appellantZip: '94103',
  availableHearingLocations: {},
  bvaPoc: null,
  centralOfficeTimeString: '04:00',
  claimantId: 604,
  closestRegionalOffice: null,
  currentIssueCount: 0,
  disposition: null,
  dispositionEditable: true,
  docketName: 'hearing',
  docketNumber: '200624-614',
  evidenceWindowWaived: false,
  externalId: '61e7af7a-586c-446d-b8ee-a65be467e9e0',
  hearingDayId: 11,
  id: 10,
  judge: {
    id: 3,
    createdAt: '2020-06-25T11:00:43.257-04:00',
    cssId: 'BVAAABSHIRE',
    efolderDocumentsFetchedAt: null,
    email: null,
    fullName: 'Aaron Judge_HearingsAndCases Abshire',
    lastLoginAt: null,
    roles: {},
    selectedRegionalOffice: null,
    stationId: '101',
    status: 'active',
    statusUpdatedAt: null,
    updatedAt: '2020-06-25T11:00:43.257-04:00',
    displayName: 'BVAAABSHIRE (VACO)',
  },
  judgeId: '3',
  location: null,
  militaryService: '',
  notes: null,
  paperCase: false,
  prepped: null,
  readableLocation: null,
  readableRequestType: 'Video',
  regionalOfficeKey: 'RO17',
  regionalOfficeName: 'St. Petersburg regional office',
  regionalOfficeTimezone: 'America/New_York',
  representative: 'PARALYZED VETERANS OF AMERICA, INC.',
  representativeName: null,
  representativeEmailAddress: 'tom.brady@caseflow.gov',
  representativeAddress: {
    addressLine1: '9999 MISSION ST',
    city: 'SAN FRANCISCO',
    state: 'CA',
    zip: '94103',
  },
  room: '1',
  scheduledFor: '2020-07-06T06:00:00.000-04:00',
  scheduledForIsPast: false,
  scheduledTime: '2000-01-01T06:00:00.000-05:00',
  scheduledTimeString: '06:00',
  summary: null,
  transcriptRequested: null,
  transcription: {},
  uuid: '61e7af7a-586c-446d-b8ee-a65be467e9e0',
  veteranAge: 85,
  veteranFileNumber: '100000005',
  veteranFirstName: 'John',
  veteranGender: 'M',
  veteranLastName: 'Smith',
  veteranEmailAddress: 'John.Smith@test.com',
  isVirtual: false,
  virtualHearing: null,
  emailEvents: [],
  wasVirtual: false,
  witness: null,
  worksheetIssues: {},
};

export const centralHearing = {
  aod: false,
  advanceOnDocketMotion: null,
  appealExternalId: 'c781353c-a911-45f4-aafa-88e1f6536eb1',
  appealId: 607,
  appellantAddressLine1: '9999 MISSION ST',
  appellantCity: 'SAN FRANCISCO',
  appellantEmailAddress: 'tom.brady@caseflow.gov',
  appellantFirstName: 'Tom',
  appellantIsNotVeteran: false,
  appellantLastName: 'Brady',
  appellantState: 'CA',
  appellantZip: '94103',
  availableHearingLocations: {},
  bvaPoc: 'Stacy BuildAndEditHearingSchedule Yellow',
  centralOfficeTimeString: '08:30',
  claimantId: 604,
  closestRegionalOffice: null,
  currentIssueCount: 0,
  disposition: null,
  dispositionEditable: true,
  docketName: 'hearing',
  docketNumber: '200629-607',
  evidenceWindowWaived: false,
  externalId: '45331d90-6498-4f49-8248-772906f4161f',
  hearingDayId: 6,
  id: 7,
  judge: {
    id: 5,
    createdAt: '2020-06-30T14:57:05.457-04:00',
    cssId: 'BVAEBECKER',
    efolderDocumentsFetchedAt: null,
    email: null,
    fullName: 'Elizabeth Judge_CaseToAssign Becker',
    lastLoginAt: null,
    roles: {},
    selectedRegionalOffice: null,
    stationId: '101',
    status: 'active',
    statusUpdatedAt: null,
    updatedAt: '2020-06-30T14:57:05.457-04:00',
    displayName: 'BVAEBECKER (VACO)',
  },
  judgeId: '5',
  location: null,
  militaryService: '',
  notes: null,
  paperCase: false,
  prepped: null,
  readableLocation: 'Washington, DC',
  readableRequestType: 'Central',
  regionalOfficeKey: 'C',
  regionalOfficeName: 'Central',
  regionalOfficeTimezone: 'America/New_York',
  representative: 'PARALYZED VETERANS OF AMERICA, INC.',
  representativeName: null,
  representativeEmailAddress: 'tom.brady@caseflow.gov',
  room: '1',
  scheduledFor: '2020-07-11T08:30:00.000-04:00',
  scheduledForIsPast: false,
  scheduledTime: '2000-01-01T08:30:00.000-05:00',
  scheduledTimeString: '08:30',
  summary: null,
  transcriptRequested: null,
  transcription: {},
  uuid: '45331d90-6498-4f49-8248-772906f4161f',
  veteranAge: 85,
  veteranFileNumber: '100000002',
  veteranFirstName: 'Kathlene',
  veteranGender: 'M',
  veteranLastName: 'Morissette',
  veteranEmailAddress: 'Kathlene.Morissette@test.com',
  isVirtual: false,
  appellantTz: 'America/New_York',
  wasVirtual: false,
  witness: null,
  worksheetIssues: {},
};

export const defaultHearingDay = {
  hearingId: 36,
  regionalOffice: 'RO17',
  timezone: 'America/New_York',
  scheduledFor: '2020-08-15',
  requestType: 'V',
  room: '001',
  roomLabel: '',
  filledSlots: 0,
  totalSlots: 12,
  hearingDate: '2020-08-15'
};

export const hearingDateOptions = [
  {
    label: ' ',
    value: {
      hearingId: null,
      hearingDate: null
    }
  },
  {
    label: '08/15/2020 (0/12)  ',
    value: defaultHearingDay
  },
  {
    label: '08/21/2020 (2/12) 1 (1W200A) ',
    value: {
      hearingId: 11,
      regionalOffice: 'RO17',
      timezone: 'America/New_York',
      scheduledFor: '2020-08-21',
      requestType: 'V',
      room: '1',
      roomLabel: '1 (1W200A)',
      filledSlots: 2,
      totalSlots: 12,
      hearingDate: '2020-08-21'
    }
  },
  {
    label: '09/01/2020 (2/12) 1 (1W200A) ',
    value: {
      hearingId: 12,
      regionalOffice: 'RO17',
      timezone: 'America/New_York',
      scheduledFor: '2020-09-01',
      requestType: 'V',
      room: '1',
      roomLabel: '1 (1W200A)',
      filledSlots: 2,
      totalSlots: 12,
      hearingDate: '2020-09-01'
    }
  },
  {
    label: '09/12/2020 (2/12) 1 (1W200A) ',
    value: {
      hearingId: 13,
      regionalOffice: 'RO17',
      timezone: 'America/New_York',
      scheduledFor: '2020-09-12',
      requestType: 'V',
      room: '1',
      roomLabel: '1 (1W200A)',
      filledSlots: 2,
      totalSlots: 12,
      hearingDate: '2020-09-12'
    }
  },
  {
    label: '09/23/2020 (0/12) 1 (1W200A) ',
    value: {
      hearingId: 14,
      regionalOffice: 'RO17',
      timezone: 'America/New_York',
      scheduledFor: '2020-09-23',
      requestType: 'V',
      room: '1',
      roomLabel: '1 (1W200A)',
      filledSlots: 0,
      totalSlots: 12,
      hearingDate: '2020-09-23'
    }
  },
  {
    label: '10/04/2020 (0/12) 1 (1W200A) ',
    value: {
      hearingId: 15,
      regionalOffice: 'RO17',
      timezone: 'America/New_York',
      scheduledFor: '2020-10-04',
      requestType: 'V',
      room: '1',
      roomLabel: '1 (1W200A)',
      filledSlots: 13,
      totalSlots: 12,
      hearingDate: '2020-10-04'
    }
  }
];

export const scheduledHearing = {
  taskId: '123',
  disposition: null,
  externalId: '3afefa82-5736-47c8-a977-0b4b8586f73e',
  polling: false,
  action: 'schedule'
};

export const scheduleVeteranResponse = {
  body: {
    tasks: {
      data: [scheduleHearingTask]
    }
  }
};
export const getHearingType = (hearing) => {
  const lastRowLabel = `${hearing.caseType} · ${hearing.readableRequestType} · View Case Details`;

  return lastRowLabel;
};

export const getHearingDetails = (hearing, showNumber) => {
  const docketNumber = showNumber && ` ${hearing.docketNumber}`;
  const issues = `${hearing.currentIssueCount} issues`;
  const docket = `${hearing.docketName.toUpperCase().charAt(0)}Hearing Request${docketNumber}`;
  const secondRowLabel = `${issues} · ${docket} · ${hearing.poaName}`;

  return secondRowLabel;
};

export const getHearingDetailsArray = (hearing, showNumber) => {
  const docketNumber = showNumber && ` ${hearing.docketNumber}`;
  const issues = `${hearing.currentIssueCount} issues`;
  const docket = `${hearing.docketName.toUpperCase().charAt(0)} Hearing Request${docketNumber}`;
  const secondRowLabel = `${issues} · ${docket} · ${hearing.poaName}`;

  return secondRowLabel.split(' ');
};

export const generateHearingDays = (regionalOffice, count) =>
  Object.assign({}, times(count).map((index) => ({
    regionalOffice,
    id: index,
    readableRequestType: regionalOffice === 'C' ? 'Central' : 'Video',
    hearingId: index,
    timezone: regionalOfficesJsonResponse.regional_offices[regionalOffice].timezone,
    scheduledFor: moment().add(index, 'days').
      format('MM-DD-YYYY'),
    requestType: regionalOffice === 'C' ? 'C' : 'V',
    room: '1',
    roomLabel: '1 (1W200A)',
    filledSlots: 2,
    totalSlots: 12,
  })));

/* eslint-enable max-lines */
