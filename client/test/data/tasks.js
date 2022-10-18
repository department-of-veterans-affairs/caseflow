import COPY from '../../COPY';
/* eslint-disable camelcase */
export const task = {
  appeal: {
    vbms_id: '516517691',
    dispatch_decision_type: 'Remand',
    decisions: [
      {
        label: null,
      },
    ],
    non_canceled_end_products_within_30_days: [],
    pending_eps: [],
    station_key: '397',
    regional_office_key: 'RO11',
  },
  user: 'a',
};

const amaTaskData = {
  uniqueId: null,
  isLegacy: false,
  type: null,
  appealType: null,
  addedByCssId: null,
  appealId: '123',
  externalAppealId: '23423534',
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
        'vba_317',
      ],
      facility_locator_id: 'vba_317',
      label: 'St. Petersburg regional office',
      city: 'St. Petersburg',
    },
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
    type: 'Bva',
  },
  assignedBy: {
    firstName: null,
    lastName: null,
    cssId: null,
    pgId: '1',
  },
  cancelledBy: {
    cssId: null,
  },
  convertedBy: {
    cssId: null,
  },
  convertedOn: null,
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
  isFormerTravel: null,
};

export const scheduleHearingTask = {
  ...amaTaskData,
  uniqueId: '1',
  type: 'ScheduleHearingTask',
  status: 'completed',
  closedAt: '2020-09-08T14:13:33.878-04:00',
  instructions: [COPY.SCHEDULE_HEARING_TASK_DEFAULT_INSTRUCTIONS],
  timelineTitle: 'ScheduleHearingTask completed',
  docketName: 'hearing',
  externalHearingId: '93897397',
};

export const changeHearingRequestTypeTask = {
  ...amaTaskData,
  uniqueId: '2',
  type: 'ChangeHearingRequestTypeTask',
  label: 'Change hearing request type',
  appealType: 'LegacyAppeal',
  status: 'completed',
  closedAt: '2020-09-08T14:13:33.878-04:00',
  convertedOn: '2020-09-08T14:13:33.878-04:00',
  convertedBy: {
    cssId: 'BVASYELLOW',
  },
  instructions: [COPY.CHANGE_HEARING_REQUEST_TYPE_TASK_DEFAULT_INSTRUCTIONS],
  timelineTitle: 'Hearing type converted from Travel to Virtual',
  docketName: 'hearing',
  externalHearingId: '93897397',
};

export const changeHearingRequestTypeTaskCancelAction = {
  label: 'Cancel convert hearing to virtual',
  func: 'cancel_convert_hearing_request_type_data',
  value: 'modal/cancel_task',
  data: {
    redirect_after: '/queue/appeals/1986897',
    modal_title: 'Cancel convert hearing to virtual task',
    message_title: "Task for Merlin V Langworth's case has been cancelled",
    message_detail:
      'You have successfully cancelled the convert hearing to virtual task',
    show_instructions: false,
  },
};

export const generateAmaTask = (overrides = {}) => ({
  ...amaTaskData,
  ...overrides,
});

export const splitAppealTask = {
  ...amaTaskData,
  uniqueId: '8663',
  isLegacy: false,
  type: 'SplitAppealTask',
  appealType: 'Appeal',
  addedByCssId: null,
  appealId: 2016,
  externalAppealId: 'c482facd-e8d1-4dac-8a2f-7190be5aa282',
  assignedOn: '2022-10-12T23:46:22.005-04:00',
  closestRegionalOffice: null,
  createdAt: '2022-10-12T23:47:12.935-04:00',
  closedAt: '2022-10-12T23:47:12.949-04:00',
  startedAt: null,
  assigneeName: 'SPLTAPPLSNOW',
  assignedTo: {
    cssId: 'SPLTAPPLSNOW',
    name: 'SPLTAPPLSNOW',
    id: 82,
    isOrganization: false,
    type: 'User'
  },
  assignedBy: {
    firstName: 'Jon',
    lastName: 'Snow',
    cssId: 'SPLTAPPLSNOW',
    pgId: 82
  },
  cancelledBy: {
    cssId: null
  },
  cancelReason: null,
  convertedBy: {
    cssId: null
  },
  convertedOn: null,
  taskId: '8663',
  parentId: 8661,
  label: 'Split Appeal Task',
  documentId: null,
  externalHearingId: null,
  workProduct: null,
  previousTaskAssignedOn: null,
  placedOnHoldAt: null,
  status: 'completed',
  onHoldDuration: null,
  instructions: [
    'Originate from different Administrations (i.e. VBA and VHA)'
  ],
  decisionPreparedBy: null,
  availableActions: [],
  timelineTitle: 'SplitAppealTask completed',
  hideFromQueueTableView: false,
  hideFromTaskSnapshot: false,
  hideFromCaseTimeline: false,
  availableHearingLocations: [],
  latestInformalHearingPresentationTask: {},
  canMoveOnDocketSwitch: false,
  timerEndsAt: null,
  unscheduledHearingNotes: {}
};

/* eslint-enable camelcase */
