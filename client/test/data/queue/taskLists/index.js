import { formatISO, sub } from 'date-fns';
import COPY from '../../../../COPY';

const getAmaTaskTemplate = ({ id = 1 } = {}) => ({
  id,
  type: 'task_column',
  attributes: {
    docket_name: 'direct_review',
    docket_number: `200603-7${id}`,
    external_appeal_id: 'fe583ee4-6f58-41a6-b8c5-09bfdc987c75',
    paper_case: null,
    veteran_full_name: `John Doe ${id}`,
    veteran_file_number: `50000000${id}`,
    started_at: null,
    issue_count: null,
    aod: false,
    case_type: 'Original',
    label: 'Stayed appeal',
    placed_on_hold_at: null,
    on_hold_duration: null,
    status: null,
    assigned_at: formatISO(sub(new Date(), { days: 2 })),
    closest_regional_office: null,
    assigned_to: {
      css_id: null,
      is_organization: null,
      name: null,
      type: null,
      id: null,
    },
    assigned_by: {
      first_name: 'Steve',
      last_name: 'Casper',
      css_id: 'BVASCASPER1',
      pg_id: 1,
    },
    power_of_attorney_name: null,
    suggested_hearing_location: null,
    assignee_name: null,
    is_legacy: null,
    type: null,
    appeal_id: null,
    created_at: null,
    closed_at: null,
    instructions: null,
    appeal_type: null,
    timeline_title: null,
    hide_from_queue_table_view: null,
    hide_from_case_timeline: null,
    hide_from_task_snapshot: null,
    docket_range_date: null,
    external_hearing_id: null,
    available_hearing_locations: null,
    previous_task: {
      assigned_at: null,
    },
    document_id: null,
    decision_prepared_by: {
      first_name: null,
      last_name: null,
    },
    available_actions: [],
    cancelled_by: {
      css_id: null,
    },
    converted_by: {
      css_id: null,
    },
    converted_on: null,
  },
});

const amaTaskWith = ({ id, ...rest }) => {
  const amaTaskTemplate = getAmaTaskTemplate({ id });

  return {
    ...amaTaskTemplate,
    ...rest,
    attributes: {
      ...amaTaskTemplate.attributes,
      ...rest.attributes,
    },
  };
};

export const daysOnHold = 31;

export const taskNewAssigned = () => amaTaskWith({ id: '1' });

export const completedHoldTask = () =>
  amaTaskWith({
    id: '2',
    attributes: {
      assigned_at: formatISO(sub(new Date(), { days: daysOnHold + 1 })),
      placed_on_hold_at: formatISO(sub(new Date(), { days: daysOnHold })),
      on_hold_duration: daysOnHold - 1,
    },
  });

export const taskOnHold = () =>
  amaTaskWith({
    id: '3',
    attributes: {
      placed_on_hold_at: formatISO(sub(new Date(), { days: 2 })),
      on_hold_duration: daysOnHold,
      status: 'on_hold',
    },
  });

export const noOnHoldDurationTask = () =>
  amaTaskWith({
    id: '4',
    attributes: {
      assigned_at: formatISO(sub(new Date(), { days: daysOnHold + 1 })),
      placed_on_hold_at: formatISO(sub(new Date(), { days: daysOnHold })),
      status: 'on_hold',
    },
  });

export const getQueueConfig = () => ({
  active_tab: 'assigned',
  table_title: 'Your cases',
  tabs: [
    {
      allow_bulk_assign: false,
      columns: [
        {
          filter_options: [],
          filterable: false,
          name: 'badgesColumn',
        },
        {
          filter_options: [],
          filterable: false,
          name: 'detailsColumn',
        },
        {
          filter_options: [],
          filterable: true,
          name: 'taskColumn',
        },
        {
          filter_options: [],
          filterable: true,
          name: 'typeColumn',
        },
        {
          filter_options: [],
          filterable: true,
          name: 'docketNumberColumn',
        },
        {
          filter_options: [],
          filterable: false,
          name: 'daysWaitingColumn',
        },
        {
          filter_options: [],
          filterable: false,
          name: 'readerLinkColumn',
        },
      ],
      description: 'Cases assigned to you:',
      label: 'Assigned (%d)',
      name: 'assigned_person',
      task_page_count: 1,
      task_page_endpoint_base_path: 'task_pages?tab=assigned_person',
      tasks: [taskNewAssigned(), completedHoldTask()],
      total_task_count: 2,
    },
    {
      allow_bulk_assign: false,
      columns: [
        {
          filter_options: [],
          filterable: false,
          name: 'badgesColumn',
        },
        {
          filter_options: [],
          filterable: false,
          name: 'detailsColumn',
        },
        {
          filter_options: [],
          filterable: true,
          name: 'taskColumn',
        },
        {
          filter_options: [],
          filterable: true,
          name: 'typeColumn',
        },
        {
          filter_options: [],
          filterable: true,
          name: 'docketNumberColumn',
        },
        {
          filter_options: [],
          filterable: false,
          name: 'daysOnHoldColumn',
        },
        {
          filter_options: [],
          filterable: false,
          name: 'readerLinkWithNewDocIconColumn',
        },
      ],
      description:
        'Cases on hold (will return to "Assigned" tab when hold is completed):',
      label: 'On hold (%d)',
      name: 'on_hold_person',
      task_page_count: 1,
      task_page_endpoint_base_path: 'task_pages?tab=on_hold_person',
      tasks: [taskOnHold(), noOnHoldDurationTask()],
      total_task_count: 2,
    },
    {
      allow_bulk_assign: false,
      columns: [
        {
          filter_options: [],
          filterable: false,
          name: 'badgesColumn',
        },
        {
          filter_options: [],
          filterable: false,
          name: 'detailsColumn',
        },
        {
          filter_options: [],
          filterable: true,
          name: 'taskColumn',
        },
        {
          filter_options: [],
          filterable: true,
          name: 'typeColumn',
        },
        {
          filter_options: [],
          filterable: true,
          name: 'docketNumberColumn',
        },
        {
          filter_options: [],
          filterable: false,
          name: 'completedDateColumn',
        },
        {
          filter_options: [],
          filterable: false,
          name: 'completedToNameColumn',
        },
        {
          filter_options: [],
          filterable: false,
          name: 'readerLinkColumn',
        },
      ],
      description: 'Cases completed (last 7 days):',
      label: 'Completed',
      name: 'completed_person',
      task_page_count: 0,
      task_page_endpoint_base_path: 'task_pages?tab=completed_person',
      tasks: [],
      total_task_count: 0,
    },
  ],
  tasks_per_page: 15,
  use_task_pages_api: false,
});

export const completedReviewTranscriptTaskNoErrorsFoundData = {
  uniqueId: '8115',
  isLegacy: false,
  type: 'ReviewTranscriptTask',
  appealType: 'Appeal',
  addedByCssId: null,
  appealId: 1880,
  externalAppealId: 'ba0ae03c-2331-4d79-ba1b-8c8089130979',
  assignedOn: '2024-08-05T10:57:27.269-04:00',
  closestRegionalOffice: null,
  createdAt: '2024-09-04T10:57:27.317-04:00',
  closedAt: '2024-09-04T10:57:27.315-04:00',
  startedAt: '2024-08-12T10:57:27.315-04:00',
  assigneeName: "Board of Veterans' Appeals",
  assignedTo: {
    cssId: null,
    name: "Board of Veterans' Appeals",
    id: 7,
    isOrganization: true,
    type: 'Bva'
  },
  assignedBy: {
    firstName: 'Lauren',
    lastName: 'Roth',
    cssId: 'CSSID1847365',
    pgId: 2579
  },
  completedBy: {
    cssId: '123'
  },
  cancelledBy: {
    cssId: null
  },
  cancelReason: null,
  convertedBy: {
    cssId: null
  },
  convertedOn: null,
  taskId: '8110',
  parentId: 8109,
  label: 'Schedule hearing',
  documentId: null,
  externalHearingId: '6a59e69b-9ecb-4332-a0fb-b07fa2ce214f',
  workProduct: null,
  caseType: 'Original',
  aod: false,
  previousTaskAssignedOn: null,
  placedOnHoldAt: null,
  status: 'completed',
  onHoldDuration: null,
  instructions: [
    COPY.REVIEW_TRANSCRIPT_TASK_DEFAULT_INSTRUCTIONS,
    COPY.UPLOAD_TRANSCRIPTION_VBMS_NO_ERRORS_ACTION_TYPE,
    'These are some notes'
  ],
  decisionPreparedBy: null,
  availableActions: [],
  timelineTitle: 'ReviewTranscriptTask completed',
  hideFromQueueTableView: false,
  hideFromTaskSnapshot: false,
  hideFromCaseTimeline: false,
  availableHearingLocations: [],
  latestInformalHearingPresentationTask: {},
  canMoveOnDocketSwitch: false,
  timerEndsAt: null,
  unscheduledHearingNotes: {},
  ownedBy: "Board of Veterans' Appeals",
  daysSinceLastStatusChange: 47,
  daysSinceBoardIntake: 47,
  id: '8115',
  claimant: {},
  appeal_receipt_date: '2024-06-18'
};

export const cancelledReviewTranscriptTaskCancelTaskData = {
  uniqueId: '3188',
  isLegacy: false,
  type: 'ReviewTranscriptTask',
  appealType: 'Appeal',
  addedByCssId: null,
  appealId: 23,
  externalAppealId: '597513a0-9468-4785-8def-50cadf924138',
  assignedOn: '2024-10-31T12:04:46.326-04:00',
  closestRegionalOffice: null,
  createdAt: '2024-10-31T12:04:46.326-04:00',
  closedAt: '2024-10-31T12:07:50.081-04:00',
  startedAt: null,
  assigneeName: 'BVASYELLOW',
  assignedTo: {
    cssId: 'BVASYELLOW',
    name: 'BVASYELLOW',
    id: 121,
    isOrganization: false,
    type: 'User'
  },
  assignedBy: {
    firstName: 'System',
    lastName: 'User',
    cssId: 'CASEFLOW1',
    pgId: 1
  },
  completedBy: { cssId: null },
  cancelledBy: { cssId: 'BVASYELLOW' },
  cancelReason: null,
  convertedBy: { cssId: null },
  convertedOn: null,
  taskId: '3188',
  parentId: 84,
  label: 'Review Transcript task',
  documentId: null,
  externalHearingId: null,
  workProduct: null,
  caseType: 'Original',
  aod: false,
  previousTaskAssignedOn: null,
  placedOnHoldAt: null,
  status: 'cancelled',
  onHoldDuration: null,
  instructions: [
    'Review the hearing transcript and upload the final to VBMS once it has been reviewed for errors or corrected.',
    'Cancel task',
    'these are cancellation notes'
  ],
  decisionPreparedBy: null,
  availableActions: [],
  timelineTitle: 'ReviewTranscriptTask completed',
  hideFromQueueTableView: false,
  hideFromTaskSnapshot: false,
  hideFromCaseTimeline: false,
  availableHearingLocations: [],
  latestInformalHearingPresentationTask: {},
  canMoveOnDocketSwitch: false,
  timerEndsAt: null,
  unscheduledHearingNotes: {},
  ownedBy: 'BVASYELLOW',
  daysSinceLastStatusChange: 0,
  daysSinceBoardIntake: 0,
  id: '3188',
  claimant: {},
  appeal_receipt_date: '2024-09-12'
};
