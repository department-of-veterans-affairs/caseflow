export const queueConfigData = {
  table_title: 'VHA CAMO cases',
  active_tab: 'unassignedTab',
  tasks_per_page: 15,
  use_task_pages_api: true,
  tabs: [
    {
      label: 'Assigned (%d)',
      name: 'camo_assigned',
      description: 'Cases assigned to you:',
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
          name: 'issueTypesColumn',
          filterable: false,
          filter_options: []
        },
        {
          name: 'taskColumn',
          filterable: true,
          filter_options: [
            {
              value: 'RootTask',
              displayText: 'Root Task (6)'
            },
            {
              value: 'VhaDocumentSearchTask',
              displayText: 'Review Documentation (63)'
            }
          ]
        },
        {
          name: 'issueCountColumn',
          filterable: false,
          filter_options: []
        },
        {
          name: 'daysWaitingColumn',
          filterable: false,
          filter_options: []
        },
        {
          name: 'typeColumn',
          filterable: true,
          filter_options: [
            {
              value: 'Original',
              displayText: 'Original (43)'
            },
            {
              value: '%253C%253Cblank%253E%253E',
              displayText: '<<blank>> (26)'
            }
          ]
        },
        {
          name: 'assignedToColumn',
          filterable: true,
          filter_options: [
            {
              value: 'VHA%2520CAMO',
              displayText: 'VHA CAMO (69)'
            }
          ]
        }
      ],
      allow_bulk_assign: false,
      contains_legacy_tasks: false,
      defaultSort: {
        sortColName: 'typeColumn',
        sortAscending: true
      },
      tasks: [
        {
          id: '12380',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-08',
            docket_number: '230508-3369',
            external_appeal_id: '2643d3d2-eb33-4d80-aa89-7fb3ed7a15cb',
            paper_case: null,
            veteran_full_name: 'Bob Smithfeil',
            veteran_file_number: '359060002',
            started_at: null,
            issue_count: 3,
            issue_types: 'Caregiver | Revocation/Discharge,Spina Bifida Treatment (Non-Compensation),Spina Bifida Treatment (Non-Compensation)',
            aod: false,
            case_type: 'Original',
            label: 'Review Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-03T20:04:04.770-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'VHA CAMO',
              type: 'VhaCamo',
              id: 39
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'INTAKE_USER',
              pg_id: 4076
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'VHA CAMO',
            days_since_last_status_change: 15,
            days_since_board_intake: 15,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '12392',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-08',
            docket_number: '230508-3373',
            external_appeal_id: 'e3b8efb9-0df2-4a6f-9d25-9e7e08220699',
            paper_case: null,
            veteran_full_name: 'Bob Smithaltenwerth',
            veteran_file_number: '359060010',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Tier Level',
            aod: false,
            case_type: 'Original',
            label: 'Review Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-03T20:04:09.709-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'VHA CAMO',
              type: 'VhaCamo',
              id: 39
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'INTAKE_USER',
              pg_id: 4076
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'VHA CAMO',
            days_since_last_status_change: 15,
            days_since_board_intake: 15,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '12398',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-08',
            docket_number: '230508-3375',
            external_appeal_id: '1efdb823-bed1-46f3-94a9-08782139af23',
            paper_case: null,
            veteran_full_name: 'Bob Smithdeckow',
            veteran_file_number: '359060014',
            started_at: null,
            issue_count: 3,
            issue_types: 'CHAMPVA,Other,Eligibility for Dental Treatment',
            aod: false,
            case_type: 'Original',
            label: 'Review Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-04T20:04:10.427-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'VHA CAMO',
              type: 'VhaCamo',
              id: 39
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'INTAKE_USER',
              pg_id: 4076
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'VHA CAMO',
            days_since_last_status_change: 15,
            days_since_board_intake: 15,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '12410',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-08',
            docket_number: '230508-3379',
            external_appeal_id: 'cfafaee0-edc5-4eb5-8a46-d4180796be94',
            paper_case: null,
            veteran_full_name: 'Bob Smithgreenfelder',
            veteran_file_number: '359060022',
            started_at: null,
            issue_count: 1,
            issue_types: 'Initial Eligibility and Enrollment in VHA Healthcare',
            aod: false,
            case_type: 'Original',
            label: 'Review Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-08T20:04:12.304-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'VHA CAMO',
              type: 'VhaCamo',
              id: 39
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'INTAKE_USER',
              pg_id: 4076
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'VHA CAMO',
            days_since_last_status_change: 15,
            days_since_board_intake: 15,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '12416',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-08',
            docket_number: '230508-3381',
            external_appeal_id: 'e7443ce3-0380-4986-a288-8d24ed66994e',
            paper_case: null,
            veteran_full_name: 'Bob Smithwiegand',
            veteran_file_number: '359060026',
            started_at: null,
            issue_count: 2,
            issue_types: 'Caregiver | Other,Eligibility for Dental Treatment',
            aod: false,
            case_type: 'Original',
            label: 'Review Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-04T20:04:13.117-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'VHA CAMO',
              type: 'VhaCamo',
              id: 39
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'INTAKE_USER',
              pg_id: 4076
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'VHA CAMO',
            days_since_last_status_change: 15,
            days_since_board_intake: 15,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '12425',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-08',
            docket_number: '230508-3384',
            external_appeal_id: 'fa16812f-4940-451d-89fd-9935a15ef8ec',
            paper_case: null,
            veteran_full_name: 'Bob Smithwolf',
            veteran_file_number: '359070032',
            started_at: null,
            issue_count: 4,
            issue_types: 'Spina Bifida Treatment (Non-Compensation),Caregiver | Revocation/Discharge,Eligibility for Dental Treatment,Initial Eligibility and Enrollment in VHA Healthcare',
            aod: false,
            case_type: 'Original',
            label: 'Review Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-08T20:05:19.183-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'VHA CAMO',
              type: 'VhaCamo',
              id: 39
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'INTAKE_USER',
              pg_id: 4076
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'VHA CAMO',
            days_since_last_status_change: 15,
            days_since_board_intake: 15,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '12440',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-08',
            docket_number: '230508-3389',
            external_appeal_id: '70e839a8-d8e2-4e5a-9128-92b56f06d0f1',
            paper_case: null,
            veteran_full_name: 'Bob Smithkirlin',
            veteran_file_number: '359070042',
            started_at: null,
            issue_count: 2,
            issue_types: 'Foreign Medical Program,Caregiver | Other',
            aod: false,
            case_type: 'Original',
            label: 'Review Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-07T20:05:21.018-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'VHA CAMO',
              type: 'VhaCamo',
              id: 39
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'INTAKE_USER',
              pg_id: 4076
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'VHA CAMO',
            days_since_last_status_change: 15,
            days_since_board_intake: 15,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '12449',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-08',
            docket_number: '230508-3392',
            external_appeal_id: 'eef94a42-3d4a-4c49-a531-1322cf7501d4',
            paper_case: null,
            veteran_full_name: 'Bob Smithrobel',
            veteran_file_number: '359070048',
            started_at: null,
            issue_count: 2,
            issue_types: 'Initial Eligibility and Enrollment in VHA Healthcare,Caregiver | Tier Level',
            aod: false,
            case_type: 'Original',
            label: 'Review Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-06T20:05:22.041-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'VHA CAMO',
              type: 'VhaCamo',
              id: 39
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'INTAKE_USER',
              pg_id: 4076
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'VHA CAMO',
            days_since_last_status_change: 15,
            days_since_board_intake: 15,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '12458',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-08',
            docket_number: '230508-3395',
            external_appeal_id: '28843470-c551-4338-a022-afc8a8bcae6b',
            paper_case: null,
            veteran_full_name: 'Bob Smithrenner',
            veteran_file_number: '359070054',
            started_at: null,
            issue_count: 4,
            issue_types: 'Caregiver | Other,Clothing Allowance,Initial Eligibility and Enrollment in VHA Healthcare,Caregiver | Other',
            aod: false,
            case_type: 'Original',
            label: 'Review Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-03T20:05:23.081-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'VHA CAMO',
              type: 'VhaCamo',
              id: 39
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'INTAKE_USER',
              pg_id: 4076
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'VHA CAMO',
            days_since_last_status_change: 15,
            days_since_board_intake: 15,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '12473',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-08',
            docket_number: '230508-3400',
            external_appeal_id: '522ed917-f16c-4edb-9eb0-3da63b63f4ac',
            paper_case: null,
            veteran_full_name: 'Bob Smithblick',
            veteran_file_number: '359070064',
            started_at: null,
            issue_count: 2,
            issue_types: 'Camp Lejune Family Member,Caregiver | Other',
            aod: false,
            case_type: 'Original',
            label: 'Review Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-05T20:05:24.916-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'VHA CAMO',
              type: 'VhaCamo',
              id: 39
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'INTAKE_USER',
              pg_id: 4076
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'VHA CAMO',
            days_since_last_status_change: 15,
            days_since_board_intake: 15,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '12494',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-08',
            docket_number: '230508-3407',
            external_appeal_id: 'e6ce3913-4511-41f7-b57d-cec273076545',
            paper_case: null,
            veteran_full_name: 'Bob Smithtreutel',
            veteran_file_number: '359070078',
            started_at: null,
            issue_count: 1,
            issue_types: 'Prosthetics | Other (not clothing allowance)',
            aod: false,
            case_type: 'Original',
            label: 'Review Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-04T20:05:29.373-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'VHA CAMO',
              type: 'VhaCamo',
              id: 39
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'INTAKE_USER',
              pg_id: 4076
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'VHA CAMO',
            days_since_last_status_change: 15,
            days_since_board_intake: 15,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '12500',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-08',
            docket_number: '230508-3409',
            external_appeal_id: 'a98d6896-26d0-4942-a6f6-b2f1439e16d9',
            paper_case: null,
            veteran_full_name: 'Bob Smithlowe',
            veteran_file_number: '359070082',
            started_at: null,
            issue_count: 4,
            issue_types: 'Caregiver | Other,Caregiver | Tier Level,Foreign Medical Program,Camp Lejune Family Member',
            aod: false,
            case_type: 'Original',
            label: 'Review Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-04T20:05:29.981-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'VHA CAMO',
              type: 'VhaCamo',
              id: 39
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'INTAKE_USER',
              pg_id: 4076
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'VHA CAMO',
            days_since_last_status_change: 15,
            days_since_board_intake: 15,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '12515',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-08',
            docket_number: '230508-3414',
            external_appeal_id: '3aefbfdd-78ad-4472-a7be-d5dde93191a2',
            paper_case: null,
            veteran_full_name: 'Bob Smithernser',
            veteran_file_number: '359070092',
            started_at: null,
            issue_count: 1,
            issue_types: 'Other',
            aod: false,
            case_type: 'Original',
            label: 'Review Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-03T20:05:31.883-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'VHA CAMO',
              type: 'VhaCamo',
              id: 39
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'INTAKE_USER',
              pg_id: 4076
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'VHA CAMO',
            days_since_last_status_change: 15,
            days_since_board_intake: 15,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '12521',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-08',
            docket_number: '230508-3416',
            external_appeal_id: '418479ba-a065-4211-9a49-ffbff9889805',
            paper_case: null,
            veteran_full_name: 'Bob Smithbahringer',
            veteran_file_number: '359070096',
            started_at: null,
            issue_count: 2,
            issue_types: 'Eligibility for Dental Treatment,Initial Eligibility and Enrollment in VHA Healthcare',
            aod: false,
            case_type: 'Original',
            label: 'Review Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-05T20:05:32.461-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'VHA CAMO',
              type: 'VhaCamo',
              id: 39
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'INTAKE_USER',
              pg_id: 4076
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'VHA CAMO',
            days_since_last_status_change: 15,
            days_since_board_intake: 15,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '12530',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-08',
            docket_number: '230508-3419',
            external_appeal_id: '307a5e0f-927f-48f1-a558-c3ae026e58b2',
            paper_case: null,
            veteran_full_name: 'Bob Smithhayes',
            veteran_file_number: '359070102',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Revocation/Discharge',
            aod: false,
            case_type: 'Original',
            label: 'Review Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-05T20:05:36.550-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'VHA CAMO',
              type: 'VhaCamo',
              id: 39
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'INTAKE_USER',
              pg_id: 4076
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'VHA CAMO',
            days_since_last_status_change: 15,
            days_since_board_intake: 15,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
      task_page_count: 5,
      total_task_count: 69,
      task_page_endpoint_base_path: '/organizations/vha-camo/task_pages?tab=camo_assigned'
    },
    {
      label: 'In Progress (%d)',
      name: 'camo_in_progress',
      description: 'Cases that are in progress:',
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
          name: 'issueTypesColumn',
          filterable: false,
          filter_options: []
        },
        {
          name: 'taskColumn',
          filterable: true,
          filter_options: [
            {
              value: 'AssessDocumentationTask',
              displayText: 'Assess Documentation (141)'
            }
          ]
        },
        {
          name: 'issueCountColumn',
          filterable: false,
          filter_options: []
        },
        {
          name: 'daysWaitingColumn',
          filterable: false,
          filter_options: []
        },
        {
          name: 'typeColumn',
          filterable: true,
          filter_options: [
            {
              value: 'Original',
              displayText: 'Original (41)'
            },
            {
              value: '%253C%253Cblank%253E%253E',
              displayText: '<<blank>> (100)'
            }
          ]
        },
        {
          name: 'assignedToColumn',
          filterable: true,
          filter_options: [
            {
              value: 'Community%2520Care%2520-%2520Payment%2520Operations%2520Management',
              displayText: 'Community Care - Payment Operations Management (44)'
            },
            {
              value: 'Community%2520Care%2520-%2520Veteran%2520and%2520Family%2520Members%2520Program',
              displayText: 'Community Care - Veteran and Family Members Program (21)'
            },
            {
              value: 'Member%2520Services%2520-%2520Beneficiary%2520Travel',
              displayText: 'Member Services - Beneficiary Travel (24)'
            },
            {
              value: 'Member%2520Services%2520-%2520Health%2520Eligibility%2520Center',
              displayText: 'Member Services - Health Eligibility Center (26)'
            },
            {
              value: 'Prosthetics',
              displayText: 'Prosthetics (26)'
            }
          ]
        }
      ],
      allow_bulk_assign: false,
      contains_legacy_tasks: false,
      defaultSort: {
        sortColName: 'typeColumn',
        sortAscending: true
      },
      tasks: [
        {
          id: '12800',
          type: 'task_column',
          attributes: {
            instructions: [
              'sdf'
            ],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-08',
            docket_number: '230508-3403',
            external_appeal_id: '814512e0-fa20-42b3-92d2-40b2c4052b06',
            paper_case: null,
            veteran_full_name: 'Bob Smithdoyle',
            veteran_file_number: '359070070',
            started_at: null,
            issue_count: 3,
            issue_types: 'Camp Lejune Family Member,CHAMPVA,Beneficiary Travel',
            aod: false,
            case_type: 'Original',
            label: 'Assess Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-05-19T12:45:19.999-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Community Care - Payment Operations Management',
              type: 'VhaProgramOffice',
              id: 41
            },
            assigned_by: {
              first_name: 'Tyler',
              last_name: 'User',
              css_id: 'SUPERUSER',
              pg_id: 4080
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'Community Care - Payment Operations Management',
            days_since_last_status_change: 4,
            days_since_board_intake: 4,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '13098',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-21',
            docket_number: '230521-3607',
            external_appeal_id: '13dddc98-633f-4d8d-94df-c11caa32b0f5',
            paper_case: null,
            veteran_full_name: 'Bob Smithveum',
            veteran_file_number: '477680002',
            started_at: null,
            issue_count: 2,
            issue_types: 'Camp Lejune Family Member,Beneficiary Travel',
            aod: false,
            case_type: 'Original',
            label: 'Assess Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-19T13:34:57.454-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Community Care - Payment Operations Management',
              type: 'VhaProgramOffice',
              id: 41
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'Community Care - Payment Operations Management',
            days_since_last_status_change: 1,
            days_since_board_intake: 1,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '13108',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-21',
            docket_number: '230521-3610',
            external_appeal_id: 'fb5a0206-8ff7-4067-b334-26e082fd17f7',
            paper_case: null,
            veteran_full_name: 'Bob Smithmurphy',
            veteran_file_number: '477690008',
            started_at: null,
            issue_count: 4,
            issue_types: 'Beneficiary Travel,Prosthetics | Other (not clothing allowance),Initial Eligibility and Enrollment in VHA Healthcare,Caregiver | Tier Level',
            aod: false,
            case_type: 'Original',
            label: 'Assess Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-20T13:35:01.780-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Community Care - Payment Operations Management',
              type: 'VhaProgramOffice',
              id: 41
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'Community Care - Payment Operations Management',
            days_since_last_status_change: 1,
            days_since_board_intake: 1,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '13124',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-21',
            docket_number: '230521-3615',
            external_appeal_id: '3de110a8-bc24-45af-b4f7-6a8d56025644',
            paper_case: null,
            veteran_full_name: 'Bob Smithbins',
            veteran_file_number: '477690018',
            started_at: null,
            issue_count: 4,
            issue_types: 'Foreign Medical Program,Eligibility for Dental Treatment,Eligibility for Dental Treatment,Clothing Allowance',
            aod: false,
            case_type: 'Original',
            label: 'Assess Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-17T13:35:03.266-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Community Care - Payment Operations Management',
              type: 'VhaProgramOffice',
              id: 41
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'Community Care - Payment Operations Management',
            days_since_last_status_change: 1,
            days_since_board_intake: 1,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '13140',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-21',
            docket_number: '230521-3620',
            external_appeal_id: '38d0a455-3b06-4070-9c93-a85cdc2f9bae',
            paper_case: null,
            veteran_full_name: 'Bob Smithtrantow',
            veteran_file_number: '477690028',
            started_at: null,
            issue_count: 1,
            issue_types: 'Beneficiary Travel',
            aod: false,
            case_type: 'Original',
            label: 'Assess Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-20T13:35:04.649-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Community Care - Payment Operations Management',
              type: 'VhaProgramOffice',
              id: 41
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'Community Care - Payment Operations Management',
            days_since_last_status_change: 1,
            days_since_board_intake: 1,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '13147',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-21',
            docket_number: '230521-3622',
            external_appeal_id: '89776ff6-7854-4794-9eae-cffb9e97054f',
            paper_case: null,
            veteran_full_name: 'Bob Smithschulist',
            veteran_file_number: '477690032',
            started_at: null,
            issue_count: 2,
            issue_types: 'Camp Lejune Family Member,Caregiver | Tier Level',
            aod: false,
            case_type: 'Original',
            label: 'Assess Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-21T13:35:05.233-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Community Care - Payment Operations Management',
              type: 'VhaProgramOffice',
              id: 41
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'Community Care - Payment Operations Management',
            days_since_last_status_change: 1,
            days_since_board_intake: 1,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '13157',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-21',
            docket_number: '230521-3625',
            external_appeal_id: '1f00d96d-b619-4c55-af56-d4ec26ee4f06',
            paper_case: null,
            veteran_full_name: 'Bob Smithkoch',
            veteran_file_number: '477690038',
            started_at: null,
            issue_count: 4,
            issue_types: 'Caregiver | Eligibility,Caregiver | Revocation/Discharge,Camp Lejune Family Member,Initial Eligibility and Enrollment in VHA Healthcare',
            aod: false,
            case_type: 'Original',
            label: 'Assess Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-21T13:35:06.053-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Community Care - Payment Operations Management',
              type: 'VhaProgramOffice',
              id: 41
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'Community Care - Payment Operations Management',
            days_since_last_status_change: 1,
            days_since_board_intake: 1,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '13173',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-21',
            docket_number: '230521-3630',
            external_appeal_id: '1122269d-110d-4858-bcd6-2cb71aff8e54',
            paper_case: null,
            veteran_full_name: 'Bob Smithreichert',
            veteran_file_number: '477690048',
            started_at: null,
            issue_count: 2,
            issue_types: 'Medical and Dental Care Reimbursement,CHAMPVA',
            aod: false,
            case_type: 'Original',
            label: 'Assess Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-22T13:35:07.485-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Community Care - Payment Operations Management',
              type: 'VhaProgramOffice',
              id: 41
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'Community Care - Payment Operations Management',
            days_since_last_status_change: 1,
            days_since_board_intake: 1,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '13183',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-21',
            docket_number: '230521-3633',
            external_appeal_id: '37ffb86c-88c4-48d3-b767-b011272e61f7',
            paper_case: null,
            veteran_full_name: 'Bob Smithgoyette',
            veteran_file_number: '477690054',
            started_at: null,
            issue_count: 3,
            issue_types: 'Caregiver | Eligibility,Other,Initial Eligibility and Enrollment in VHA Healthcare',
            aod: false,
            case_type: 'Original',
            label: 'Assess Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-20T13:35:08.276-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Community Care - Payment Operations Management',
              type: 'VhaProgramOffice',
              id: 41
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'Community Care - Payment Operations Management',
            days_since_last_status_change: 1,
            days_since_board_intake: 1,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '13196',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-21',
            docket_number: '230521-3637',
            external_appeal_id: '5310a073-17ab-4b89-8c0c-9be07a5c9bed',
            paper_case: null,
            veteran_full_name: 'Bob Smithwiegand',
            veteran_file_number: '477690062',
            started_at: null,
            issue_count: 2,
            issue_types: 'Prosthetics | Other (not clothing allowance),Clothing Allowance',
            aod: false,
            case_type: 'Original',
            label: 'Assess Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-22T13:35:09.419-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Community Care - Payment Operations Management',
              type: 'VhaProgramOffice',
              id: 41
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'Community Care - Payment Operations Management',
            days_since_last_status_change: 1,
            days_since_board_intake: 1,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '13206',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-21',
            docket_number: '230521-3640',
            external_appeal_id: 'faef0837-096a-488d-8dec-5e75e32fd9ef',
            paper_case: null,
            veteran_full_name: 'Bob Smithbergnaum',
            veteran_file_number: '477690068',
            started_at: null,
            issue_count: 2,
            issue_types: 'Prosthetics | Other (not clothing allowance),Clothing Allowance',
            aod: false,
            case_type: 'Original',
            label: 'Assess Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-19T13:35:10.291-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Community Care - Payment Operations Management',
              type: 'VhaProgramOffice',
              id: 41
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'Community Care - Payment Operations Management',
            days_since_last_status_change: 1,
            days_since_board_intake: 1,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '13216',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-21',
            docket_number: '230521-3643',
            external_appeal_id: '09bf94da-3b2b-439b-9e02-7d092807c48b',
            paper_case: null,
            veteran_full_name: 'Bob Smithlindgren',
            veteran_file_number: '477690074',
            started_at: null,
            issue_count: 3,
            issue_types: 'Caregiver | Tier Level,Foreign Medical Program,Spina Bifida Treatment (Non-Compensation)',
            aod: false,
            case_type: 'Original',
            label: 'Assess Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-22T13:35:11.158-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Community Care - Payment Operations Management',
              type: 'VhaProgramOffice',
              id: 41
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'Community Care - Payment Operations Management',
            days_since_last_status_change: 1,
            days_since_board_intake: 1,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '13229',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-21',
            docket_number: '230521-3647',
            external_appeal_id: '9bcdfe8f-b7ed-470f-aad1-cd2ddb736380',
            paper_case: null,
            veteran_full_name: 'Bob Smithhane',
            veteran_file_number: '477690082',
            started_at: null,
            issue_count: 1,
            issue_types: 'Caregiver | Tier Level',
            aod: false,
            case_type: 'Original',
            label: 'Assess Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-18T13:35:12.272-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Community Care - Payment Operations Management',
              type: 'VhaProgramOffice',
              id: 41
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'Community Care - Payment Operations Management',
            days_since_last_status_change: 1,
            days_since_board_intake: 1,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '13236',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-21',
            docket_number: '230521-3649',
            external_appeal_id: '77f53f38-7800-410b-b356-0033d3992c24',
            paper_case: null,
            veteran_full_name: 'Bob Smithhackett',
            veteran_file_number: '477690086',
            started_at: null,
            issue_count: 2,
            issue_types: 'Continuing Eligibility/Income Verification Match (IVM),Caregiver | Eligibility',
            aod: false,
            case_type: 'Original',
            label: 'Assess Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-18T13:35:12.800-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Community Care - Payment Operations Management',
              type: 'VhaProgramOffice',
              id: 41
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'Community Care - Payment Operations Management',
            days_since_last_status_change: 1,
            days_since_board_intake: 1,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '13246',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-21',
            docket_number: '230521-3652',
            external_appeal_id: '126aab8c-69fd-4cf1-9fbf-054987da968f',
            paper_case: null,
            veteran_full_name: 'Bob Smithmurray',
            veteran_file_number: '477690092',
            started_at: null,
            issue_count: 1,
            issue_types: 'Clothing Allowance',
            aod: false,
            case_type: 'Original',
            label: 'Assess Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'assigned',
            assigned_at: '2023-04-19T13:35:13.596-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'Community Care - Payment Operations Management',
              type: 'VhaProgramOffice',
              id: 41
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'Community Care - Payment Operations Management',
            days_since_last_status_change: 1,
            days_since_board_intake: 1,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
      task_page_count: 10,
      total_task_count: 141,
      task_page_endpoint_base_path: '/organizations/vha-camo/task_pages?tab=camo_in_progress'
    },
    {
      label: 'Completed',
      name: 'completed',
      description: 'Cases assigned to you:',
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
          name: 'issueTypesColumn',
          filterable: false,
          filter_options: []
        },
        {
          name: 'taskColumn',
          filterable: true,
          filter_options: [
            {
              value: 'RootTask',
              displayText: 'Root Task (6)'
            },
            {
              value: 'VhaDocumentSearchTask',
              displayText: 'Review Documentation (63)'
            }
          ]
        },
        {
          name: 'issueCountColumn',
          filterable: false,
          filter_options: []
        },
        {
          name: 'daysWaitingColumn',
          filterable: false,
          filter_options: []
        },
        {
          name: 'typeColumn',
          filterable: true,
          filter_options: [
            {
              value: 'Original',
              displayText: 'Original (43)'
            },
            {
              value: '%253C%253Cblank%253E%253E',
              displayText: '<<blank>> (26)'
            }
          ]
        },
        {
          name: 'assignedToColumn',
          filterable: true,
          filter_options: [
            {
              value: 'VHA%2520CAMO',
              displayText: 'VHA CAMO (69)'
            }
          ]
        }
      ],
      allow_bulk_assign: false,
      contains_legacy_tasks: false,
      defaultSort: {
        sortColName: 'typeColumn',
        sortAscending: true
      },
      tasks: [
        {
          id: '12905',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-18',
            docket_number: '230518-3543',
            external_appeal_id: '36831409-da89-434d-9a0d-0d69532b482a',
            paper_case: null,
            veteran_full_name: 'Bob Smithmacgyver',
            veteran_file_number: '452120070',
            started_at: '2023-04-20T14:34:54.618-04:00',
            issue_count: 2,
            issue_types: 'Continuing Eligibility/Income Verification Match (IVM),Medical and Dental Care Reimbursement',
            aod: false,
            case_type: 'Original',
            label: 'Review Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'completed',
            assigned_at: '2023-04-15T14:34:54.434-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'VHA CAMO',
              type: 'VhaCamo',
              id: 39
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'INTAKE_USER',
              pg_id: 4076
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'VHA CAMO',
            days_since_last_status_change: 4,
            days_since_board_intake: 4,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '12914',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-18',
            docket_number: '230518-3546',
            external_appeal_id: '1926d141-3ccb-4b04-b9b3-edbd244a198d',
            paper_case: null,
            veteran_full_name: 'Bob Smithcrooks',
            veteran_file_number: '452120076',
            started_at: '2023-04-27T14:34:55.801-04:00',
            issue_count: 3,
            issue_types: 'CHAMPVA,Eligibility for Dental Treatment,Prosthetics | Other (not clothing allowance)',
            aod: false,
            case_type: 'Original',
            label: 'Review Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'completed',
            assigned_at: '2023-04-17T14:34:55.599-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'VHA CAMO',
              type: 'VhaCamo',
              id: 39
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'INTAKE_USER',
              pg_id: 4076
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'VHA CAMO',
            days_since_last_status_change: 4,
            days_since_board_intake: 4,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '12926',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-18',
            docket_number: '230518-3550',
            external_appeal_id: 'd3889ed6-b0b4-453e-a59d-28143235827b',
            paper_case: null,
            veteran_full_name: 'Bob Smithernser',
            veteran_file_number: '452120084',
            started_at: '2023-04-21T14:34:57.424-04:00',
            issue_count: 4,
            issue_types: 'Camp Lejune Family Member,Eligibility for Dental Treatment,CHAMPVA,Eligibility for Dental Treatment',
            aod: false,
            case_type: 'Original',
            label: 'Review Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'completed',
            assigned_at: '2023-04-14T14:34:57.232-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'VHA CAMO',
              type: 'VhaCamo',
              id: 39
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'INTAKE_USER',
              pg_id: 4076
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'VHA CAMO',
            days_since_last_status_change: 4,
            days_since_board_intake: 4,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '12941',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-18',
            docket_number: '230518-3555',
            external_appeal_id: '2f40ef05-ea98-4bf6-8d08-b1716013abde',
            paper_case: null,
            veteran_full_name: 'Bob Smithbruen',
            veteran_file_number: '452120094',
            started_at: '2023-04-25T14:34:59.398-04:00',
            issue_count: 1,
            issue_types: 'Foreign Medical Program',
            aod: false,
            case_type: 'Original',
            label: 'Review Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'completed',
            assigned_at: '2023-04-19T14:34:59.183-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'VHA CAMO',
              type: 'VhaCamo',
              id: 39
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'INTAKE_USER',
              pg_id: 4076
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'VHA CAMO',
            days_since_last_status_change: 4,
            days_since_board_intake: 4,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
          id: '12947',
          type: 'task_column',
          attributes: {
            instructions: [],
            docket_name: 'evidence_submission',
            appeal_receipt_date: '2023-05-18',
            docket_number: '230518-3557',
            external_appeal_id: '7492b7b6-c3b2-4d35-9f23-e40b2adf9eaa',
            paper_case: null,
            veteran_full_name: 'Bob Smithbarrows',
            veteran_file_number: '452120098',
            started_at: '2023-04-19T14:35:00.091-04:00',
            issue_count: 4,
            issue_types: 'CHAMPVA,Prosthetics | Other (not clothing allowance),Caregiver | Eligibility,Caregiver | Eligibility',
            aod: false,
            case_type: 'Original',
            label: 'Review Documentation',
            placed_on_hold_at: null,
            on_hold_duration: null,
            status: 'completed',
            assigned_at: '2023-04-14T14:34:59.912-04:00',
            closest_regional_office: null,
            assigned_to: {
              css_id: null,
              is_organization: true,
              name: 'VHA CAMO',
              type: 'VhaCamo',
              id: 39
            },
            assigned_by: {
              first_name: 'Lauren',
              last_name: 'Roth',
              css_id: 'INTAKE_USER',
              pg_id: 4076
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
            latest_informal_hearing_presentation_task: {},
            owned_by: 'VHA CAMO',
            days_since_last_status_change: 4,
            days_since_board_intake: 4,
            assignee_name: null,
            is_legacy: null,
            type: null,
            appeal_id: null,
            created_at: null,
            closed_at: null,
            appeal_type: null,
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
      total_task_count: 5,
      task_page_endpoint_base_path: '/organizations/vha-camo/task_pages?tab=completed'
    }
  ]
};
