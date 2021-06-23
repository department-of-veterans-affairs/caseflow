import { formatISO, sub } from 'date-fns';

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
    assigned_at: formatISO(sub(new Date(), { hours: 47 })),
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
