/* eslint-disable camelcase */
export const task = {
  appeal: {
    vbms_id: '516517691',
    dispatch_decision_type: 'Remand',
    decisions: [
      {
        label: null
      }
    ],
    non_canceled_end_products_within_30_days: [],
    pending_eps: [],
    station_key: '397',
    regional_office_key: 'RO11'
  },
  user: 'a'
};

export const scheduledHearingTask = {
  id: '123',
  type: 'task',
  attributes: {
    is_legacy: false,
    type: 'ScheduleHearingTask',
    label: 'Schedule hearing',
    appeal_id: 348,
    status: 'completed',
    assigned_at: '2020-09-08T10:02:49.210-04:00',
    started_at: null,
    created_at: '2020-09-08T10:02:49.210-04:00',
    closed_at: '2020-09-08T14:13:33.878-04:00',
    instructions: [
      'Schedule Veteran and/or appellant for Board hearing.'
    ],
    appeal_type: 'Appeal',
    parent_id: 974,
    timeline_title: 'ScheduleHearingTask completed',
    hide_from_queue_table_view: false,
    hide_from_case_timeline: false,
    hide_from_task_snapshot: false,
    assigned_by: {
      first_name: '',
      last_name: '',
      full_name: null,
      css_id: null,
      pg_id: null
    },
    assigned_to: {
      css_id: null,
      full_name: null,
      is_organization: true,
      name: "Board of Veterans' Appeals",
      type: 'Bva',
      id: 5
    },
    cancelled_by: {
      css_id: null
    },
    assignee_name: "Board of Veterans' Appeals",
    placed_on_hold_at: null,
    on_hold_duration: null,
    docket_name: 'hearing',
    case_type: 'Original',
    docket_number: '200907-348',
    docket_range_date: null,
    veteran_full_name: 'Brant Halvorson',
    veteran_file_number: '737469267',
    closest_regional_office: {
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
    external_appeal_id: '456',
    aod: false,
    overtime: false,
    issue_count: 1,
    external_hearing_id: '2afefa82-5736-47c8-a977-0b4b8586f73e',
    available_hearing_locations: [],
    previous_task: {
      assigned_at: null
    },
    document_id: null,
    decision_prepared_by: {
      first_name: null,
      last_name: null
    },
    available_actions: []
  }
};

/* eslint-enable camelcase */
