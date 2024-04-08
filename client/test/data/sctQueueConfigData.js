/* eslint-disable max-lines */
export const sctQueueConfigData = {
  table_title: 'Specialty Case Team cases',
  active_tab: 'unassignedTab',
  tasks_per_page: 15,
  use_task_pages_api: true,
  tabs: [
    {
      label: 'Unassigned (%d)',
      name: 'sct_unassigned',
      description: 'Cases owned by the Specialty Case Team team that are unassigned to a person.',
      columns: [
        {
          name: 'badgesColumn',
          filterable: false,
          filter_options: []
        },
        {
          name: 'detailsColumn',
          filterable: false,
          filter_options: []
        },
        {
          name: 'typeColumn',
          filterable: true,
          filter_options: [
            {
              value: 'is_aod',
              displayText: 'AOD (38)'
            },
            {
              value: 'Original',
              displayText: 'Original (40)'
            }
          ]
        },
        {
          name: 'docketNumberColumn',
          filterable: true,
          filter_options: [
            {
              value: 'evidence_submission',
              displayText: 'Evidence (22)'
            },
            {
              value: 'hearing',
              displayText: 'Hearing (18)'
            }
          ]
        },
        {
          name: 'issueCountColumn',
          filterable: false,
          filter_options: []
        },
        {
          name: 'issueTypesColumn',
          filterable: true,
          filter_options: [
            {
              value: 'None',
              displayText: 'None (1)'
            },
            {
              value: 'Caregiver%2520%257C%2520Other',
              displayText: 'Caregiver | Other (39)'
            }
          ]
        },
        {
          name: 'readerLinkColumn',
          filterable: false,
          filter_options: []
        }
      ],
      allow_bulk_assign: true,
      contains_legacy_tasks: false,
      defaultSort: {
        sortColName: 'typeColumn',
        sortAscending: true
      },
      hide_from_queue_table_view: true,
      tasks: [
        {
          id: '26773',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'hearing',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3180',
            external_appeal_id: '4d893697-75dc-4edb-94b8-bf5b2e12134c',
            paper_case: null,
            veteran_full_name: 'Bob Smithwehner',
            veteran_file_number: '621250003',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26774',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'hearing',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3181',
            external_appeal_id: 'ebda4353-9e84-42ef-888a-e1afe205e36d',
            paper_case: null,
            veteran_full_name: 'Bob Smithwalker',
            veteran_file_number: '621250005',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26772',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'hearing',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3182',
            external_appeal_id: '8ed8753b-f496-44a5-88d2-e8a846f56421',
            paper_case: null,
            veteran_full_name: 'Bob Smithshanahan',
            veteran_file_number: '621250007',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26825',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'hearing',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3184',
            external_appeal_id: '0d7366c8-1f8f-4aa5-b82f-604aa25c86c0',
            paper_case: null,
            veteran_full_name: 'Bob Smithfranecki',
            veteran_file_number: '621410011',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26824',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'hearing',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3185',
            external_appeal_id: '5c53334a-b2be-4c65-8115-e27a7ae5d5cd',
            paper_case: null,
            veteran_full_name: 'Bob Smithpredovic',
            veteran_file_number: '621410013',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26823',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'hearing',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3186',
            external_appeal_id: '67f734e9-46f0-46ca-8644-fd65ba6aa5e3',
            paper_case: null,
            veteran_full_name: 'Bob Smithsatterfield',
            veteran_file_number: '621410015',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26822',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'hearing',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3187',
            external_appeal_id: 'ba3a35aa-d838-45b0-b732-1388d0de2d8f',
            paper_case: null,
            veteran_full_name: 'Bob Smithstroman',
            veteran_file_number: '621410017',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26821',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'hearing',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3188',
            external_appeal_id: 'aa9e120f-d094-4b7a-9205-7c423616fb7d',
            paper_case: null,
            veteran_full_name: 'Bob Smithbeatty',
            veteran_file_number: '621410019',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26818',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3189',
            external_appeal_id: '9e97b1a7-7fb7-409e-b916-75d58919fc2b',
            paper_case: null,
            veteran_full_name: 'Bob Smithwillms',
            veteran_file_number: '621410021',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26816',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3190',
            external_appeal_id: '011b1df0-102b-4f98-96b3-dd411a838e95',
            paper_case: null,
            veteran_full_name: 'Bob Smithzemlak',
            veteran_file_number: '621410023',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26817',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3191',
            external_appeal_id: '331b462d-4b17-4b06-bc04-a3ae0aa123a2',
            paper_case: null,
            veteran_full_name: 'Bob Smithschaden',
            veteran_file_number: '621410025',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26814',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3192',
            external_appeal_id: '28f78e9b-a4da-4cf6-ae80-091cd8e4e9df',
            paper_case: null,
            veteran_full_name: 'Bob Smithwiegand',
            veteran_file_number: '621410027',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26815',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3193',
            external_appeal_id: '0bd53b90-a79d-453e-a9c9-2b3b5cc1adeb',
            paper_case: null,
            veteran_full_name: 'Bob Smithsteuber',
            veteran_file_number: '621410029',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26998',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3194',
            external_appeal_id: 'e579caf5-1896-410a-8ba7-acf0270ee244',
            paper_case: null,
            veteran_full_name: 'Bob Smithratke',
            veteran_file_number: '621630001',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '27001',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3195',
            external_appeal_id: 'd0a8bba6-e6c5-4cf5-ba5b-75c2609e078e',
            paper_case: null,
            veteran_full_name: 'Bob Smithrunte',
            veteran_file_number: '621630003',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        }
      ],
      task_page_count: 3,
      total_task_count: 40,
      task_page_endpoint_base_path: '/organizations/specialty-case-team/task_pages?tab=sct_unassigned'
    },
    {
      label: 'Action Required (%d)',
      name: 'action_required',
      description: 'Cases owned by the Specialty Case Team that require action:',
      columns: [
        {
          name: 'badgesColumn',
          filterable: false,
          filter_options: []
        },
        {
          name: 'detailsColumn',
          filterable: false,
          filter_options: []
        },
        {
          name: 'typeColumn',
          filterable: true,
          filter_options: [
            {
              value: 'Original',
              displayText: 'Original (1)'
            }
          ]
        },
        {
          name: 'docketNumberColumn',
          filterable: true,
          filter_options: [
            {
              value: 'evidence_submission',
              displayText: 'Evidence (1)'
            }
          ]
        },
        {
          name: 'issueCountColumn',
          filterable: false,
          filter_options: []
        },
        {
          name: 'issueTypesColumn',
          filterable: true,
          filter_options: [
            {
              value: 'Caregiver%2520%257C%2520Other',
              displayText: 'Caregiver | Other (1)'
            }
          ]
        },
        {
          name: 'readerLinkColumn',
          filterable: false,
          filter_options: []
        }
      ],
      allow_bulk_assign: false,
      contains_legacy_tasks: false,
      defaultSort: {
        sortColName: 'typeColumn',
        sortAscending: true
      },
      hide_from_queue_table_view: false,
      tasks: [
        {
          id: '27047',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2024-01-17',
            docket_number: '240117-3146',
            external_appeal_id: '42e24927-070c-48d5-91a4-fef6d39d4cfa',
            paper_case: null,
            veteran_full_name: 'Bob Smithpurdy',
            veteran_file_number: '554570002',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: false,
            case_type: 'Original',
            label: 'Review',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'on_hold',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: 'Tyler',
              last_name: 'User',
              css_id: 'SUPERUSER',
              pg_id: 4924
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        }
      ],
      task_page_count: 1,
      total_task_count: 1,
      task_page_endpoint_base_path: '/organizations/specialty-case-team/task_pages?tab=action_required'
    },
    {
      label: 'Completed',
      name: 'completed',
      description: 'Cases owned by the Specialty Case Team that have been assigned to a SCT Attorney (last 14 days):',
      columns: [
        {
          name: 'badgesColumn',
          filterable: false,
          filter_options: []
        },
        {
          name: 'detailsColumn',
          filterable: false,
          filter_options: []
        },
        {
          name: 'typeColumn',
          filterable: true,
          filter_options: [
            {
              value: 'is_aod',
              displayText: 'AOD (12)'
            },
            {
              value: 'Original',
              displayText: 'Original (16)'
            }
          ]
        },
        {
          name: 'docketNumberColumn',
          filterable: true,
          filter_options: [
            {
              value: 'evidence_submission',
              displayText: 'Evidence (10)'
            },
            {
              value: 'hearing',
              displayText: 'Hearing (6)'
            }
          ]
        },
        {
          name: 'issueCountColumn',
          filterable: false,
          filter_options: []
        },
        {
          name: 'issueTypesColumn',
          filterable: true,
          filter_options: [
            {
              value: 'Caregiver%2520%257C%2520Other',
              displayText: 'Caregiver | Other (16)'
            }
          ]
        },
        {
          name: 'readerLinkColumn',
          filterable: false,
          filter_options: []
        }
      ],
      allow_bulk_assign: false,
      contains_legacy_tasks: false,
      defaultSort: {
        sortColName: 'typeColumn',
        sortAscending: true
      },
      hide_from_queue_table_view: false,
      tasks: [
        {
          id: '26646',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3163',
            external_appeal_id: 'cc69d073-89e0-4961-835f-be990f0ae27d',
            paper_case: null,
            veteran_full_name: 'Bob Smithgusikowski',
            veteran_file_number: '619640003',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'completed',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26697',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3164',
            external_appeal_id: '21a3a5fc-dc37-4246-a404-f0824e80c313',
            paper_case: null,
            veteran_full_name: 'Bob Smithzboncak',
            veteran_file_number: '620690002',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'completed',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: true,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26696',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3165',
            external_appeal_id: '499d01f6-c46c-4085-bcf5-9078bac4b864',
            paper_case: null,
            veteran_full_name: 'Bob Smithschoen',
            veteran_file_number: '620690004',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'completed',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26700',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3166',
            external_appeal_id: 'fd121215-1a79-4101-a9cd-d55a0822820d',
            paper_case: null,
            veteran_full_name: 'Bob Smithflatley',
            veteran_file_number: '620690006',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'completed',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26698',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3167',
            external_appeal_id: '50908f08-e6fe-4de4-b688-4ed5e5ccec97',
            paper_case: null,
            veteran_full_name: 'Bob Smithcole',
            veteran_file_number: '620690008',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'completed',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26699',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3168',
            external_appeal_id: '6a309865-8128-441c-b6d3-36722b88d366',
            paper_case: null,
            veteran_full_name: 'Bob Smithaufderhar',
            veteran_file_number: '620690010',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'completed',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26708',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'hearing',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3169',
            external_appeal_id: '11f5bc42-41d3-4fe5-ba3c-206b95d68fa4',
            paper_case: null,
            veteran_full_name: 'Bob Smithconroy',
            veteran_file_number: '620700012',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'completed',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26707',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'hearing',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3170',
            external_appeal_id: 'fd5d6313-cfbd-4bd3-b85c-b0322d6678c9',
            paper_case: null,
            veteran_full_name: 'Bob Smithmuller',
            veteran_file_number: '620700014',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'completed',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26705',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'hearing',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3171',
            external_appeal_id: '008c57a7-ee81-4b79-8c9e-ac697c9a60c4',
            paper_case: null,
            veteran_full_name: 'Bob Smithdickinson',
            veteran_file_number: '620700016',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'completed',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26709',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'hearing',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3172',
            external_appeal_id: 'b11bbec2-f5af-496e-8a9d-ecf7c38ebc53',
            paper_case: null,
            veteran_full_name: 'Bob Smithhessel',
            veteran_file_number: '620700018',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'completed',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26706',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'hearing',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3173',
            external_appeal_id: 'ebb77fea-cc08-4a6a-a4a0-42287e626f27',
            paper_case: null,
            veteran_full_name: 'Bob Smithfay',
            veteran_file_number: '620700020',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'completed',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26770',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'hearing',
            appeal_receipt_date: '2022-01-25',
            docket_number: '220125-3179',
            external_appeal_id: '4ebea98f-c432-4464-9bbb-c05531ac5249',
            paper_case: null,
            veteran_full_name: 'Bob Smithweimann',
            veteran_file_number: '621250001',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: true,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'completed',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: '',
              last_name: '',
              css_id: null,
              pg_id: null
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26447',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2024-01-17',
            docket_number: '240117-3146',
            external_appeal_id: '42e24927-070c-48d5-91a4-fef6d39d4cfa',
            paper_case: null,
            veteran_full_name: 'Bob Smithpurdy',
            veteran_file_number: '554570002',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: false,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'completed',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'CSS_ID577001',
              pg_id: 15239
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26625',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2024-01-23',
            docket_number: '240123-3159',
            external_appeal_id: '947c1d64-5d74-4231-b259-8a60eb7f4e73',
            paper_case: null,
            veteran_full_name: 'Bob Smithlarkin',
            veteran_file_number: '613150002',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: false,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'completed',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'CSS_ID152001',
              pg_id: 15240
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        },
        {
          id: '26629',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2024-01-23',
            docket_number: '240123-3160',
            external_appeal_id: '39deb04d-c855-4775-a8e4-cc2b951d830f',
            paper_case: null,
            veteran_full_name: 'Bob Smithupton',
            veteran_file_number: '613620002',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Other',
            aod: false,
            case_type: 'Original',
            label: 'Assign',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'completed',
            assigned_at: null,
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Specialty Case Team',
              type: 'SpecialtyCaseTeam',
              id: 67
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'CSS_ID624001',
              pg_id: 15241
            },
            hearing_request_type: null,
            former_travel: null,
            power_of_attorney_name: null,
            suggested_hearing_location: null,
            overtime: false,
            contested_claim: false,
            veteran_appellant_deceased: false,
            document_id: null,
            decision_prepared_by: null,
            latest_informal_hearing_presentation_task: null,
            owned_by: null,
            days_since_last_status_change: null,
            days_since_board_intake: null,
            appeal_type: 'Appeal',
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            timeline_title: null,
            hide_from_queue_table_view: null,
            hide_from_case_timeline: null,
            hide_from_task_snapshot: null,
            docket_range_date: null,
            external_hearing_id: null,
            available_hearing_locations: null,
            previous_task: {
              assigned_at: null
            },
            available_actions: [],
            cancelled_by: {
              css_id: null
            },
            converted_by: {
              css_id: null
            },
            converted_on: null
          }
        }
      ],
      task_page_count: 2,
      total_task_count: 16,
      task_page_endpoint_base_path: '/organizations/specialty-case-team/task_pages?tab=completed'
    }
  ]
};
