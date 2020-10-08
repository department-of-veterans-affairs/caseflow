import COPY from '../../COPY';

const amaTaskData = {
  uniqueId: null,
  isLegacy: false,
  type: null,
  appealType: null,
  addedByCssId: null,
  appealId: "123",
  externalAppealId: "23423534",
  assignedOn: '2020-09-08T10:02:49.210-04:00',
  closestRegionalOffice: {
    key: 'RO17',
    location_hash: {
      timezone: 'America/New_York',
      state: 'FL',
      hold_hearings: true,
      alternate_locations: [
        'vba_317a',
        'vc_0742V',
        'vba_317',
        'vba_317',
        'vba_317'
      ],
      facility_locator_id: 'vba_317',
      label: 'St. Petersburg regional office',
      city: 'St. Petersburg'
    }
  },
  createdAt: '2020-09-08T10:02:49.210-04:00',
  closedAt: '2020-09-08T10:03:49.210-04:00',
  startedAt: '2020-09-08T10:02:49.210-04:00',
  assigneeName: "Board of Veterans' Appeals",
  assignedTo: {
    cssId: null,
    name: "Board of Veterans' Appeals",
    id: '1',
    isOrganization: true,
    type: 'Bva'
  },
  assignedBy: {
    firstName: null,
    lastName: null,
    cssId: null,
    pgId: '1'
  },
  cancelledBy: {
    cssId: null,
  },
  completedBy: {
    cssId: null,
  },
  completedAt: null,
  taskId: null,
  parentId: '1',
  label: null,
  documentId: null,
  externalHearingId: null,
  workProduct: null,
  previousTaskAssignedOn: null,
  placedOnHoldAt: null,
  status: null,
  onHoldDuration: null,
  instructions: null,
  decisionPreparedBy: null,
  availableActions: null,
  caseReviewId: null,
  timelineTitle: null,
  hideFromQueueTableView: false,
  hideFromTaskSnapshot: false,
  hideFromCaseTimeline: false,
  availableHearingLocations: null,
  powerOfAttorneyName: null,
  suggestedHearingLocation: null,
  hearingRequestType: null,
  isFormerTravel: null
};


export const scheduleHearingTask = {
  ...amaTaskData,
  uniqueId: '1',
  type: 'ScheduleHearingTask',
  status: 'completed',
  closedAt: '2020-09-08T14:13:33.878-04:00',
  instructions: [
    COPY.SCHEDULE_HEARING_TASK_DEFAULT_INSTRUCTIONS
  ],
  timelineTitle: 'ScheduleHearingTask completed',
  docketName: 'hearing',
  externalHearingId: '93897397'
}

export const changeHearingRequestTypeTask = {
  ...amaTaskData,
  uniqueId: '2',
  type: 'ChangeHearingRequestTypeTask',
  label: 'Change hearing request type',
  appealType: 'LegacyAppeal',
  status: 'completed',
  closedAt: '2020-09-08T14:13:33.878-04:00',
  completedAt: '2020-09-08T14:13:33.878-04:00',
  completedBy: {
    cssId: 'BVASYELLOW',
  },
  instructions: [
    COPY.CHANGE_HEARING_REQUEST_TYPE_TASK_DEFAULT_INSTRUCTIONS
  ],
  timelineTitle: 'Hearing type converted from Travel to Virtual',
  docketName: 'hearing',
  externalHearingId: '93897397'
}

