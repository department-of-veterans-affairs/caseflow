import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom/extend-expect';
import { Provider } from 'react-redux';
import CorrespondenceDetails from 'app/queue/correspondence/details/CorrespondenceDetails';
import { correspondenceDetailsData } from 'test/data/correspondence';
import { applyMiddleware, createStore } from 'redux';
import rootReducer from 'app/queue/reducers';
import thunk from 'redux-thunk';
import moment from 'moment';
import { prepareAppealForSearchStore, sortCaseTimelineEvents, prepareAppealForStore, prepareTasksForStore } from 'app/queue/utils';
import { MemoryRouter, Route } from 'react-router-dom';
import { within } from '@testing-library/dom';
import { tasksUnrelatedToAnAppeal } from 'test/data/queue/taskActionModals/taskActionModalData';
import ApiUtil from 'app/util/ApiUtil';
import { correspondenceAppeals, correspondence } from '../../../../data/correspondence';

jest.mock('redux', () => ({
  ...jest.requireActual('redux'),
  bindActionCreators: () => jest.fn().mockImplementation(() => Promise.resolve(true)),
}));

jest.mock('app/queue/utils', () => ({
  prepareAppealForSearchStore: jest.fn(),
  sortCaseTimelineEvents: jest.fn(),
  prepareAppealForStore: jest.fn(),
  prepareTasksForStore: jest.fn()
}));

jest.mock('app/queue/CaseListTable', () => ({ appeals }) => (
  <div className="case-list-table">
    <table>
      <thead>
        <tr>
          <th>Docket Number</th>
          <th>Appellant Name</th>
          <th>Appeal Status</th>
          <th>Appeal Type</th>
          <th>Number of Issues</th>
          <th>Decision Date</th>
          <th>Appeal Location</th>
        </tr>
      </thead>
      <tbody>
        {appeals.map((appeal, index) => (
          <tr key={index}>
            <td>{appeal.docketNumber}</td>
            <td>{appeal.appellant_full_name}</td>
            <td>{appeal.status}</td>
            <td>{appeal.appealType}</td>
            <td>{appeal.issueCount}</td>
            <td>{appeal.decisionDate}</td>
            <td>{appeal.location}</td>
          </tr>
        ))}
      </tbody>
    </table>
  </div>
));

jest.mock('app/util/ApiUtil', () => ({
  post: jest.fn(),
}));

let initialState = {
  correspondence: correspondenceDetailsData
};

const store = createStore(rootReducer, initialState, applyMiddleware(thunk));

let props = {
  organizations: ['Inbound Ops Team'],
  appeal: {
    externalId:'debug'
  },
  isInboundOpsUser: true,
  updateCorrespondenceRelations: jest.fn(),
  correspondence
  // correspondence: {
  //   uuid: '123',
  //   veteranFullName: 'John Doe',
  //   veteranFileNumber: '123456789',
  //   correspondenceType: 'Abeyance',
  //   nod: false,
  //   notes: 'Note Test',
  //   mailTasks: ['Task 1', 'Task 2'],
  //   all_correspondences: Array.from({ length: 30 }, (_, i) => ({ uuid: `uuid${i}`,
  //     vaDateOfReceipt: '2024-08-06T00:00:00Z',
  //     notes: `Note ${i}`,
  //     status: `Status ${i}` })),
  //   prior_mail: [
  //     { id: 1, vaDateOfReceipt: '2023-08-20T00:00:00Z' },
  //     { id: 2, vaDateOfReceipt: '2023-08-19T00:00:00Z' }
  //   ],
  //   relatedCorrespondenceIds: [2],
  //   tasksUnrelatedToAppeal: tasksUnrelatedToAnAppeal,
  //   correspondenceAppeals: [
  //     {
  //       "id": 63,
  //       "correspondencesAppealsTasks": [
  //         {
  //           "id": 44,
  //           "correspondence_appeal_id": 63,
  //           "task_id": 3203,
  //           "created_at": "2024-09-24T12:54:23.632-04:00",
  //           "updated_at": "2024-09-24T12:54:23.632-04:00"
  //         },
  //         {
  //           "id": 45,
  //           "correspondence_appeal_id": 63,
  //           "task_id": 3205,
  //           "created_at": "2024-09-24T12:54:23.696-04:00",
  //           "updated_at": "2024-09-24T12:54:23.696-04:00"
  //         },
  //         {
  //           "id": 46,
  //           "correspondence_appeal_id": 63,
  //           "task_id": 3207,
  //           "created_at": "2024-09-24T12:54:23.739-04:00",
  //           "updated_at": "2024-09-24T12:54:23.739-04:00"
  //         }
  //       ],
  //       "docketNumber": "240714-447",
  //       "veteranName": {
  //         "id": 101,
  //         "bgs_last_synced_at": null,
  //         "closest_regional_office": null,
  //         "created_at": "2024-07-15T16:47:46.377-04:00",
  //         "date_of_death": null,
  //         "date_of_death_reported_at": null,
  //         "file_number": "550000030",
  //         "first_name": "John",
  //         "last_name": "Doe",
  //         "middle_name": null,
  //         "name_suffix": "101",
  //         "participant_id": "650000030",
  //         "ssn": "787549808",
  //         "updated_at": "2024-07-15T16:47:46.377-04:00"
  //       },
  //       "streamType": "original",
  //       "appealUuid": "0f6bb359-8624-4cef-8690-0891297f224f",
  //       "appealType": "evidence_submission",
  //       "numberOfIssues": 2,
  //       "appeal": {
  //         "data": {
  //           "id": "447",
  //           "type": "appeal",
  //           "attributes": {
  //             "assigned_attorney": null,
  //             "assigned_judge": null,
  //             "appellant_hearing_email_recipient": null,
  //             "representative_hearing_email_recipient": null,
  //             "appellant_email_address": "Bob.Smithbeier@test.com",
  //             "current_user_email": null,
  //             "current_user_timezone": "America/New_York",
  //             "contested_claim": false,
  //             "mst": null,
  //             "pact": false,
  //             "issues": [],
  //             "status": "not_distributed",
  //             "decision_issues": [],
  //             "substitute_appellant_claimant_options": [
  //               {
  //                 "displayText": "BOB VANCE, Spouse",
  //                 "value": "CLAIMANT_WITH_PVA_AS_VSO"
  //               },
  //               {
  //                 "displayText": "CATHY SMITH, Child",
  //                 "value": "1129318238"
  //               },
  //               {
  //                 "displayText": "TOM BRADY, Child",
  //                 "value": "no-such-pid"
  //               }
  //             ],
  //             "nod_date_updates": [],
  //             "can_edit_request_issues": false,
  //             "hearings": [],
  //             "withdrawn": false,
  //             "removed": false,
  //             "overtime": false,
  //             "veteran_appellant_deceased": false,
  //             "assigned_to_location": "Litigation Support",
  //             "distributed_to_a_judge": false,
  //             "completed_hearing_on_previous_appeal?": false,
  //             "appellant_is_not_veteran": false,
  //             "appellant_full_name": "John Doe",
  //             "appellant_first_name": "John",
  //             "appellant_middle_name": null,
  //             "appellant_last_name": "Doe",
  //             "appellant_suffix": null,
  //             "appellant_date_of_birth": "1994-07-15",
  //             "appellant_address": {
  //               "address_line_1": "9999 MISSION ST",
  //               "address_line_2": "UBER",
  //               "address_line_3": "APT 2",
  //               "city": "SAN FRANCISCO",
  //               "zip": "94103",
  //               "country": "USA",
  //               "state": "CA"
  //             },
  //             "appellant_phone_number": null,
  //             "appellant_tz": "America/Los_Angeles",
  //             "appellant_relationship": "Veteran",
  //             "appellant_type": "VeteranClaimant",
  //             "appellant_party_type": null,
  //             "unrecognized_appellant_id": null,
  //             "has_poa": {
  //               "id": 30,
  //               "authzn_change_clmant_addrs_ind": null,
  //               "authzn_poa_access_ind": null,
  //               "claimant_participant_id": "650000030",
  //               "created_at": "2024-07-15T16:47:46.454-04:00",
  //               "file_number": "00001234",
  //               "last_synced_at": "2024-07-15T16:47:46.454-04:00",
  //               "legacy_poa_cd": "100",
  //               "poa_participant_id": "600153863",
  //               "representative_name": "Clarence Darrow",
  //               "representative_type": "Attorney",
  //               "updated_at": "2024-07-15T16:47:46.454-04:00"
  //             },
  //             "cavc_remand": null,
  //             "show_post_cavc_stream_msg": false,
  //             "remand_source_appeal_id": null,
  //             "remand_judge_name": null,
  //             "appellant_substitution": null,
  //             "substitutions": [],
  //             "veteran_death_date": null,
  //             "veteran_file_number": "550000030",
  //             "veteran_participant_id": "650000030",
  //             "efolder_link": "https://vefs-claimevidence-ui-uat.stage.bip.va.gov",
  //             "veteran_full_name": "John Doe",
  //             "closest_regional_office": null,
  //             "closest_regional_office_label": null,
  //             "available_hearing_locations": [],
  //             "external_id": "0f6bb359-8624-4cef-8690-0891297f224f",
  //             "externalId": "0f6bb359-8624-4cef-8690-0891297f224f",
  //             "type": "Original",
  //             "vacate_type": null,
  //             "aod": false,
  //             "docket_name": "evidence_submission",
  //             "docket_number": "240714-447",
  //             "docket_range_date": null,
  //             "decision_date": null,
  //             "nod_date": "2024-07-14",
  //             "withdrawal_date": null,
  //             "certification_date": null,
  //             "paper_case": false,
  //             "regional_office": null,
  //             "caseflow_veteran_id": 101,
  //             "document_id": null,
  //             "attorney_case_review_id": null,
  //             "attorney_case_rewrite_details": {
  //               "note_from_attorney": null,
  //               "untimely_evidence": null
  //             },
  //             "can_edit_document_id": false,
  //             "readable_hearing_request_type": null,
  //             "readable_original_hearing_request_type": null,
  //             "docket_switch": null,
  //             "switched_dockets": [],
  //             "has_notifications": false,
  //             "cavc_remands_with_dashboard": 0,
  //             "evidence_submission_task": {
  //               "id": 2163,
  //               "appeal_id": 447,
  //               "appeal_type": "Appeal",
  //               "assigned_at": "2024-07-15T16:47:46.499-04:00",
  //               "assigned_by_id": null,
  //               "assigned_to_id": 16,
  //               "assigned_to_type": "Organization",
  //               "cancellation_reason": null,
  //               "cancelled_by_id": null,
  //               "closed_at": null,
  //               "completed_by_id": null,
  //               "created_at": "2024-07-15T16:47:46.499-04:00",
  //               "instructions": [],
  //               "parent_id": 2162,
  //               "placed_on_hold_at": null,
  //               "started_at": null,
  //               "status": "assigned",
  //               "updated_at": "2024-07-15T16:47:46.499-04:00"
  //             },
  //             "has_completed_sct_assign_task": false
  //           }
  //         }
  //       },
  //       "taskAddedData": {
  //         "data": [
  //           {
  //             "id": "3203",
  //             "type": "task",
  //             "attributes": {
  //               "is_legacy": false,
  //               "type": "DeathCertificateMailTask",
  //               "label": "Death certificate",
  //               "appeal_id": 447,
  //               "status": "assigned",
  //               "assigned_at": "2024-09-24T12:54:23.602-04:00",
  //               "started_at": null,
  //               "created_at": "2024-09-24T12:54:23.602-04:00",
  //               "closed_at": null,
  //               "cancellation_reason": null,
  //               "instructions": [
  //                 "dc"
  //               ],
  //               "appeal_type": "Appeal",
  //               "parent_id": 3202,
  //               "timeline_title": "DeathCertificateMailTask completed",
  //               "hide_from_queue_table_view": false,
  //               "hide_from_case_timeline": false,
  //               "hide_from_task_snapshot": false,
  //               "assigned_by": {
  //                 "first_name": "Jon",
  //                 "last_name": "Admin",
  //                 "full_name": "Jon MailTeam Snow Admin",
  //                 "css_id": "INBOUND_OPS_TEAM_ADMIN_USER",
  //                 "pg_id": 65
  //               },
  //               "completed_by": null,
  //               "assigned_to": {
  //                 "css_id": null,
  //                 "full_name": "VLJ Support Staff",
  //                 "is_organization": true,
  //                 "name": "VLJ Support Staff",
  //                 "status": "active",
  //                 "type": "Colocated",
  //                 "id": 8
  //               },
  //               "cancelled_by": {
  //                 "css_id": null
  //               },
  //               "converted_by": {
  //                 "css_id": null
  //               },
  //               "converted_on": null,
  //               "assignee_name": "VLJ Support Staff",
  //               "placed_on_hold_at": null,
  //               "on_hold_duration": null,
  //               "docket_name": "evidence_submission",
  //               "case_type": "Original",
  //               "docket_number": "240714-447",
  //               "docket_range_date": null,
  //               "veteran_full_name": "John Doe",
  //               "veteran_file_number": "550000030",
  //               "closest_regional_office": null,
  //               "external_appeal_id": "0f6bb359-8624-4cef-8690-0891297f224f",
  //               "aod": false,
  //               "overtime": false,
  //               "contested_claim": false,
  //               "mst": null,
  //               "pact": false,
  //               "veteran_appellant_deceased": false,
  //               "issue_count": 0,
  //               "issue_types": "",
  //               "external_hearing_id": null,
  //               "available_hearing_locations": [],
  //               "previous_task": {
  //                 "assigned_at": null
  //               },
  //               "document_id": null,
  //               "decision_prepared_by": {
  //                 "first_name": null,
  //                 "last_name": null
  //               },
  //               "available_actions": [],
  //               "can_move_on_docket_switch": true,
  //               "timer_ends_at": null,
  //               "unscheduled_hearing_notes": null,
  //               "appeal_receipt_date": "2024-07-14",
  //               "days_since_last_status_change": 0,
  //               "days_since_board_intake": 0,
  //               "owned_by": "VLJ Support Staff"
  //             }
  //           },
  //           {
  //             "id": "3205",
  //             "type": "task",
  //             "attributes": {
  //               "is_legacy": false,
  //               "type": "AddressChangeMailTask",
  //               "label": "Change of address",
  //               "appeal_id": 447,
  //               "status": "assigned",
  //               "assigned_at": "2024-09-24T12:54:23.679-04:00",
  //               "started_at": null,
  //               "created_at": "2024-09-24T12:54:23.679-04:00",
  //               "closed_at": null,
  //               "cancellation_reason": null,
  //               "instructions": [
  //                 "coa"
  //               ],
  //               "appeal_type": "Appeal",
  //               "parent_id": 3204,
  //               "timeline_title": "AddressChangeMailTask completed",
  //               "hide_from_queue_table_view": false,
  //               "hide_from_case_timeline": false,
  //               "hide_from_task_snapshot": false,
  //               "assigned_by": {
  //                 "first_name": "Jon",
  //                 "last_name": "Admin",
  //                 "full_name": "Jon MailTeam Snow Admin",
  //                 "css_id": "INBOUND_OPS_TEAM_ADMIN_USER",
  //                 "pg_id": 65
  //               },
  //               "completed_by": null,
  //               "assigned_to": {
  //                 "css_id": null,
  //                 "full_name": "Hearing Admin",
  //                 "is_organization": true,
  //                 "name": "Hearing Admin",
  //                 "status": "active",
  //                 "type": "HearingAdmin",
  //                 "id": 39
  //               },
  //               "cancelled_by": {
  //                 "css_id": null
  //               },
  //               "converted_by": {
  //                 "css_id": null
  //               },
  //               "converted_on": null,
  //               "assignee_name": "Hearing Admin",
  //               "placed_on_hold_at": null,
  //               "on_hold_duration": null,
  //               "docket_name": "evidence_submission",
  //               "case_type": "Original",
  //               "docket_number": "240714-447",
  //               "docket_range_date": null,
  //               "veteran_full_name": "John Doe",
  //               "veteran_file_number": "550000030",
  //               "closest_regional_office": null,
  //               "external_appeal_id": "0f6bb359-8624-4cef-8690-0891297f224f",
  //               "aod": false,
  //               "overtime": false,
  //               "contested_claim": false,
  //               "mst": null,
  //               "pact": false,
  //               "veteran_appellant_deceased": false,
  //               "issue_count": 0,
  //               "issue_types": "",
  //               "external_hearing_id": null,
  //               "available_hearing_locations": [],
  //               "previous_task": {
  //                 "assigned_at": null
  //               },
  //               "document_id": null,
  //               "decision_prepared_by": {
  //                 "first_name": null,
  //                 "last_name": null
  //               },
  //               "available_actions": [],
  //               "can_move_on_docket_switch": true,
  //               "timer_ends_at": null,
  //               "unscheduled_hearing_notes": null,
  //               "appeal_receipt_date": "2024-07-14",
  //               "days_since_last_status_change": 0,
  //               "days_since_board_intake": 0,
  //               "owned_by": "Hearing Admin"
  //             }
  //           },
  //           {
  //             "id": "3207",
  //             "type": "task",
  //             "attributes": {
  //               "is_legacy": false,
  //               "type": "StatusInquiryMailTask",
  //               "label": "Status inquiry",
  //               "appeal_id": 447,
  //               "status": "assigned",
  //               "assigned_at": "2024-09-24T12:54:23.721-04:00",
  //               "started_at": null,
  //               "created_at": "2024-09-24T12:54:23.721-04:00",
  //               "closed_at": null,
  //               "cancellation_reason": null,
  //               "instructions": [
  //                 "si"
  //               ],
  //               "appeal_type": "Appeal",
  //               "parent_id": 3206,
  //               "timeline_title": "StatusInquiryMailTask completed",
  //               "hide_from_queue_table_view": false,
  //               "hide_from_case_timeline": false,
  //               "hide_from_task_snapshot": false,
  //               "assigned_by": {
  //                 "first_name": "Jon",
  //                 "last_name": "Admin",
  //                 "full_name": "Jon MailTeam Snow Admin",
  //                 "css_id": "INBOUND_OPS_TEAM_ADMIN_USER",
  //                 "pg_id": 65
  //               },
  //               "completed_by": null,
  //               "assigned_to": {
  //                 "css_id": null,
  //                 "full_name": "Litigation Support",
  //                 "is_organization": true,
  //                 "name": "Litigation Support",
  //                 "status": "active",
  //                 "type": "LitigationSupport",
  //                 "id": 18
  //               },
  //               "cancelled_by": {
  //                 "css_id": null
  //               },
  //               "converted_by": {
  //                 "css_id": null
  //               },
  //               "converted_on": null,
  //               "assignee_name": "Litigation Support",
  //               "placed_on_hold_at": null,
  //               "on_hold_duration": null,
  //               "docket_name": "evidence_submission",
  //               "case_type": "Original",
  //               "docket_number": "240714-447",
  //               "docket_range_date": null,
  //               "veteran_full_name": "John Doe",
  //               "veteran_file_number": "550000030",
  //               "closest_regional_office": null,
  //               "external_appeal_id": "0f6bb359-8624-4cef-8690-0891297f224f",
  //               "aod": false,
  //               "overtime": false,
  //               "contested_claim": false,
  //               "mst": null,
  //               "pact": false,
  //               "veteran_appellant_deceased": false,
  //               "issue_count": 0,
  //               "issue_types": "",
  //               "external_hearing_id": null,
  //               "available_hearing_locations": [],
  //               "previous_task": {
  //                 "assigned_at": null
  //               },
  //               "document_id": null,
  //               "decision_prepared_by": {
  //                 "first_name": null,
  //                 "last_name": null
  //               },
  //               "available_actions": [],
  //               "can_move_on_docket_switch": true,
  //               "timer_ends_at": null,
  //               "unscheduled_hearing_notes": null,
  //               "appeal_receipt_date": "2024-07-14",
  //               "days_since_last_status_change": 0,
  //               "days_since_board_intake": 0,
  //               "owned_by": "Litigation Support"
  //             }
  //           }
  //         ]
  //       },
  //       "status": "Pending",
  //       "assignedTo": {
  //         "id": 8,
  //         "accepts_priority_pushed_cases": null,
  //         "ama_only_push": false,
  //         "ama_only_request": false,
  //         "created_at": "2024-07-15T16:45:56.066-04:00",
  //         "exclude_appeals_from_affinity": false,
  //         "name": "VLJ Support Staff",
  //         "participant_id": null,
  //         "role": null,
  //         "status": "active",
  //         "status_updated_at": null,
  //         "updated_at": "2024-07-15T16:45:56.066-04:00",
  //         "url": "vlj-support"
  //       },
  //       "correspondence": {
  //         "id": 63,
  //         "appeal_id": 447,
  //         "correspondence_id": 555,
  //         "created_at": "2024-09-24T12:54:23.566-04:00",
  //         "updated_at": "2024-09-24T12:54:23.566-04:00"
  //       }
  //     }
  //   ],

  //   appeals_information: {
  //     appeals: [
  //       {
  //         id: 1,
  //         type: 'Correspondence',
  //         attributes: {
  //           assigned_to_location: 'Mail',
  //           appellant_full_name: 'John Doe',
  //           type: 'Original',
  //           docket_number: '123-456'
  //         }
  //       }
  //     ],
  //     claim_reviews: []
  //   }
  // }
};

describe('CorrespondenceDetails', () => {

  beforeEach(() => {
    store.dispatch = jest.fn();

    prepareAppealForSearchStore.mockReturnValue({
      appeals: {},
      appealDetails: {}
    });
    sortCaseTimelineEvents.mockReturnValue(
      tasksUnrelatedToAnAppeal
    );
    prepareAppealForStore.mockReturnValue([]);
    prepareTasksForStore.mockReturnValue({
      "3203": {
          "uniqueId": "3203",
          "isLegacy": false,
          "type": "DeathCertificateMailTask",
          "appealType": "Appeal",
          "addedByCssId": null,
          "appealId": 447,
          "externalAppealId": "0f6bb359-8624-4cef-8690-0891297f224f",
          "assignedOn": "2024-09-24T12:54:23.602-04:00",
          "closestRegionalOffice": null,
          "createdAt": "2024-09-24T12:54:23.602-04:00",
          "closedAt": null,
          "startedAt": null,
          "assigneeName": "VLJ Support Staff",
          "assignedTo": {
              "cssId": null,
              "name": "VLJ Support Staff",
              "id": 8,
              "isOrganization": true,
              "type": "Colocated"
          },
          "assignedBy": {
              "firstName": "Jon",
              "lastName": "Admin",
              "cssId": "INBOUND_OPS_TEAM_ADMIN_USER",
              "pgId": 65
          },
          "completedBy": {
              "cssId": null
          },
          "cancelledBy": {
              "cssId": null
          },
          "cancelReason": null,
          "convertedBy": {
              "cssId": null
          },
          "convertedOn": null,
          "taskId": "3203",
          "parentId": 3202,
          "label": "Death certificate",
          "documentId": null,
          "externalHearingId": null,
          "workProduct": null,
          "caseType": "Original",
          "aod": false,
          "previousTaskAssignedOn": null,
          "placedOnHoldAt": null,
          "status": "assigned",
          "onHoldDuration": null,
          "instructions": [
              "dc"
          ],
          "decisionPreparedBy": null,
          "availableActions": [],
          "timelineTitle": "DeathCertificateMailTask completed",
          "hideFromQueueTableView": false,
          "hideFromTaskSnapshot": false,
          "hideFromCaseTimeline": false,
          "availableHearingLocations": [],
          "latestInformalHearingPresentationTask": {},
          "canMoveOnDocketSwitch": true,
          "timerEndsAt": null,
          "unscheduledHearingNotes": {},
          "ownedBy": "VLJ Support Staff",
          "daysSinceLastStatusChange": 0,
          "daysSinceBoardIntake": 0,
          "id": "3203",
          "claimant": {},
          "appeal_receipt_date": "2024-07-14"
      },
      "3205": {
          "uniqueId": "3205",
          "isLegacy": false,
          "type": "AddressChangeMailTask",
          "appealType": "Appeal",
          "addedByCssId": null,
          "appealId": 447,
          "externalAppealId": "0f6bb359-8624-4cef-8690-0891297f224f",
          "assignedOn": "2024-09-24T12:54:23.679-04:00",
          "closestRegionalOffice": null,
          "createdAt": "2024-09-24T12:54:23.679-04:00",
          "closedAt": null,
          "startedAt": null,
          "assigneeName": "Hearing Admin",
          "assignedTo": {
              "cssId": null,
              "name": "Hearing Admin",
              "id": 39,
              "isOrganization": true,
              "type": "HearingAdmin"
          },
          "assignedBy": {
              "firstName": "Jon",
              "lastName": "Admin",
              "cssId": "INBOUND_OPS_TEAM_ADMIN_USER",
              "pgId": 65
          },
          "completedBy": {
              "cssId": null
          },
          "cancelledBy": {
              "cssId": null
          },
          "cancelReason": null,
          "convertedBy": {
              "cssId": null
          },
          "convertedOn": null,
          "taskId": "3205",
          "parentId": 3204,
          "label": "Change of address",
          "documentId": null,
          "externalHearingId": null,
          "workProduct": null,
          "caseType": "Original",
          "aod": false,
          "previousTaskAssignedOn": null,
          "placedOnHoldAt": null,
          "status": "assigned",
          "onHoldDuration": null,
          "instructions": [
              "coa"
          ],
          "decisionPreparedBy": null,
          "availableActions": [],
          "timelineTitle": "AddressChangeMailTask completed",
          "hideFromQueueTableView": false,
          "hideFromTaskSnapshot": false,
          "hideFromCaseTimeline": false,
          "availableHearingLocations": [],
          "latestInformalHearingPresentationTask": {},
          "canMoveOnDocketSwitch": true,
          "timerEndsAt": null,
          "unscheduledHearingNotes": {},
          "ownedBy": "Hearing Admin",
          "daysSinceLastStatusChange": 0,
          "daysSinceBoardIntake": 0,
          "id": "3205",
          "claimant": {},
          "appeal_receipt_date": "2024-07-14"
      },
      "3207": {
          "uniqueId": "3207",
          "isLegacy": false,
          "type": "StatusInquiryMailTask",
          "appealType": "Appeal",
          "addedByCssId": null,
          "appealId": 447,
          "externalAppealId": "0f6bb359-8624-4cef-8690-0891297f224f",
          "assignedOn": "2024-09-24T12:54:23.721-04:00",
          "closestRegionalOffice": null,
          "createdAt": "2024-09-24T12:54:23.721-04:00",
          "closedAt": null,
          "startedAt": null,
          "assigneeName": "Litigation Support",
          "assignedTo": {
              "cssId": null,
              "name": "Litigation Support",
              "id": 18,
              "isOrganization": true,
              "type": "LitigationSupport"
          },
          "assignedBy": {
              "firstName": "Jon",
              "lastName": "Admin",
              "cssId": "INBOUND_OPS_TEAM_ADMIN_USER",
              "pgId": 65
          },
          "completedBy": {
              "cssId": null
          },
          "cancelledBy": {
              "cssId": null
          },
          "cancelReason": null,
          "convertedBy": {
              "cssId": null
          },
          "convertedOn": null,
          "taskId": "3207",
          "parentId": 3206,
          "label": "Status inquiry",
          "documentId": null,
          "externalHearingId": null,
          "workProduct": null,
          "caseType": "Original",
          "aod": false,
          "previousTaskAssignedOn": null,
          "placedOnHoldAt": null,
          "status": "assigned",
          "onHoldDuration": null,
          "instructions": [
              "si"
          ],
          "decisionPreparedBy": null,
          "availableActions": [],
          "timelineTitle": "StatusInquiryMailTask completed",
          "hideFromQueueTableView": false,
          "hideFromTaskSnapshot": false,
          "hideFromCaseTimeline": false,
          "availableHearingLocations": [],
          "latestInformalHearingPresentationTask": {},
          "canMoveOnDocketSwitch": true,
          "timerEndsAt": null,
          "unscheduledHearingNotes": {},
          "ownedBy": "Litigation Support",
          "daysSinceLastStatusChange": 0,
          "daysSinceBoardIntake": 0,
          "id": "3207",
          "claimant": {},
          "appeal_receipt_date": "2024-07-14"
      }
  })

    render(
      <Provider store={store}>
        <MemoryRouter>
          <Route>
            <CorrespondenceDetails {...props} />
          </Route>
        </MemoryRouter>
      </Provider>
    );
  });

  it('toggles view all correspondence', () => {
    const viewAllButton = screen.getByText('View all correspondence');

    fireEvent.click(viewAllButton);
    expect(screen.getByText('Hide all correspondence')).toBeInTheDocument();
  });

  it('renders the component', () => {
    const userNameCount = screen.getAllByText('John Doe').length;

    expect(userNameCount).toBeGreaterThan(0);
    const packageDetailsTab = screen.getByText('Package Details');
    // const responseLettersTab = screen.getByText('Response Letters');
    const associatedPriorMailTab = screen.getByText('Associated Prior Mail');

    expect(screen.getByText('Veteran ID:')).toBeInTheDocument();
    expect(screen.getByText('Correspondence and Appeal Tasks')).toBeInTheDocument();
    expect(screen.getByText('Package Details')).toBeInTheDocument();
    expect(screen.getByText('Response Letters')).toBeInTheDocument();
    expect(screen.getByText('Associated Prior Mail')).toBeInTheDocument();
    expect(screen.getByText('View all correspondence')).toBeInTheDocument();
    expect(screen.getByText('Tasks not related to an appeal')).toBeInTheDocument();
    expect(screen.getByText('Completed Mail Tasks')).toBeInTheDocument();
    expect(screen.getByText('Task 1')).toBeInTheDocument();
    expect(screen.getByText('Task 2')).toBeInTheDocument();

    // Existing Appeals Table and Columns
    expect(screen.getByText('Existing Appeals')).toBeInTheDocument();
    expect(screen.getByText('Appellant Name')).toBeInTheDocument();
    expect(screen.getByText('Appeal Status')).toBeInTheDocument();
    expect(screen.getByText('Appeal Type')).toBeInTheDocument();
    expect(screen.getByText('Number of Issues')).toBeInTheDocument();
    expect(screen.getByText('Decision Date')).toBeInTheDocument();
    expect(screen.getByText('Appeal Location')).toBeInTheDocument();
    expect(screen.getByText('View veteran documents')).toBeInTheDocument();

    // Appeals related
    const existingAppeals = screen.getAllByText('Tasks added to appeal').length;

    expect(existingAppeals).toBe(2);
    expect(screen.getByText('240714-253')).toBeInTheDocument();
    expect(screen.getByText('240714-254')).toBeInTheDocument();
    expect(screen.getByText('VLJ Support Staff')).toBeInTheDocument();
    expect(screen.getByText('Hearing Admin')).toBeInTheDocument();

    // Appeals related
    const tasksAddedTextCount = screen.getAllByText('Tasks added to appeal').length;

    expect(tasksAddedTextCount).toBe(2);
    expect(screen.getByText('240714-253')).toBeInTheDocument();
    expect(screen.getByText('240714-254')).toBeInTheDocument();
    expect(screen.getByText('VLJ Support Staff')).toBeInTheDocument();
    expect(screen.getByText('Hearing Admin')).toBeInTheDocument();

    // Clicks on the Package Details Tab and tests its expectations
    fireEvent.click(packageDetailsTab);
    expect(screen.getByText('Veteran Details')).toBeInTheDocument();
    expect(screen.getByText(props.correspondence.veteranFullName)).toBeInTheDocument();
    expect(screen.getByText('Correspondence Type')).toBeInTheDocument();
    expect(screen.getByText(props.correspondence.correspondenceType)).toBeInTheDocument();
    expect(screen.getByText('Package Document Type')).toBeInTheDocument();
    expect(screen.getByText('Non-NOD')).toBeInTheDocument();
    expect(screen.getByText('VA DOR')).toBeInTheDocument();
    expect(screen.getByText(moment(props.correspondence.vaDateOfReceipt).format('MM/DD/YYYY'))).toBeInTheDocument();
    expect(screen.getByText('Notes')).toBeInTheDocument();
    expect(screen.getByText(props.correspondence.notes)).toBeInTheDocument();

    fireEvent.click(associatedPriorMailTab);
    expect(screen.getByText('Please select prior mail to link to this correspondence')).toBeInTheDocument();
    const priorDate = new Date(props.correspondence.prior_mail[0].vaDateOfReceipt);

    expect(screen.getByText(priorDate.toLocaleDateString('en-US'))).toBeInTheDocument();
  });

  it('validates the options of the actions dropdown based on the task type', () => {
    const table = document.querySelector('#case-timeline-table');

    expect(table).toBeInTheDocument();

    const tasksUnrelatedToAppeal = props.correspondence.tasksUnrelatedToAppeal;

    tasksUnrelatedToAppeal.forEach((task) => {
      const label = task.label;
      const labelElement = screen.getAllByText(label, { selector: 'dd' })[0];
      const tableRow = labelElement.closest('tr');

      expect(tableRow).toBeInTheDocument();

      const dropdown = within(tableRow).getByRole('combobox');

      expect(dropdown).toBeInTheDocument();
      fireEvent.mouseDown(dropdown);

      // Find the listbox which contains the dropdown options
      const listbox = screen.getByRole('listbox', { name: /available-actions-listbox/i });

      // Ensure the listbox is present in the DOM
      expect(listbox).toBeInTheDocument();
      const options = within(listbox).getAllByRole('option');
      const optionLabels = options.map((option) => option.textContent.trim());

      expect(options).toHaveLength(task.availableActions.length);
      expect(optionLabels.sort()).toEqual(task.availableActions.map((action) => action.label).sort());
    });
  });

  it('validates save changes button', () => {

    let saveChangesButton = screen.getAllByText('Save changes')[0];

    expect(saveChangesButton).toBeInTheDocument();
    expect(saveChangesButton).toBeDisabled();
  });

  it('onPriorMailCheckboxChange selects/deselects prior mail and enables/disables the submit button', () => {

    const associatedPriorMailTab = screen.getByText('Associated Prior Mail');

    fireEvent.click(associatedPriorMailTab);
    // Check the checkbox for the first prior mail item
    const checkbox = screen.getByRole('checkbox', { name: '1' });

    fireEvent.click(checkbox);

    // Check that the checkbox is checked and the submit button is enabled
    expect(checkbox).toBeChecked();
    expect(screen.getByText('Save changes')).not.toBeDisabled();

    // Uncheck the checkbox
    fireEvent.click(checkbox);

    // Check that the checkbox is unchecked and the submit button is disabled
    expect(checkbox).not.toBeChecked();
    expect(screen.getByText('Save changes')).toBeDisabled();
  });

  it('saveChanges sends API request and updates correspondence relations', async () => {
    const associatedPriorMailTab = screen.getByText('Associated Prior Mail');

    fireEvent.click(associatedPriorMailTab);
    const checkbox = screen.getByRole('checkbox', { name: '1' });
    fireEvent.click(checkbox);

    // Mock API call
    const apiResponse = Promise.resolve();

    ApiUtil.post.mockReturnValueOnce(apiResponse);

    // Click the Save button
    fireEvent.click(screen.getByText('Save changes'));

    // Check if API call was made
    expect(ApiUtil.post).toHaveBeenCalledWith(
        `/queue/correspondence/${props.correspondence.uuid}/create_correspondence_relations`,
        { data: { priorMailIds: [1] } }
    );
  });
});

describe('Correspondence details without beforeEach', () => {

  beforeEach(() => {
    store.dispatch = jest.fn();

    prepareAppealForSearchStore.mockReturnValue({
      appeals: {},
      appealDetails: {}
    });
    sortCaseTimelineEvents.mockReturnValue(
      tasksUnrelatedToAnAppeal
    );
    prepareAppealForStore.mockReturnValue([]);
    prepareTasksForStore.mockReturnValue({
      "3203": {
          "uniqueId": "3203",
          "isLegacy": false,
          "type": "DeathCertificateMailTask",
          "appealType": "Appeal",
          "addedByCssId": null,
          "appealId": 447,
          "externalAppealId": "0f6bb359-8624-4cef-8690-0891297f224f",
          "assignedOn": "2024-09-24T12:54:23.602-04:00",
          "closestRegionalOffice": null,
          "createdAt": "2024-09-24T12:54:23.602-04:00",
          "closedAt": null,
          "startedAt": null,
          "assigneeName": "VLJ Support Staff",
          "assignedTo": {
              "cssId": null,
              "name": "VLJ Support Staff",
              "id": 8,
              "isOrganization": true,
              "type": "Colocated"
          },
          "assignedBy": {
              "firstName": "Jon",
              "lastName": "Admin",
              "cssId": "INBOUND_OPS_TEAM_ADMIN_USER",
              "pgId": 65
          },
          "completedBy": {
              "cssId": null
          },
          "cancelledBy": {
              "cssId": null
          },
          "cancelReason": null,
          "convertedBy": {
              "cssId": null
          },
          "convertedOn": null,
          "taskId": "3203",
          "parentId": 3202,
          "label": "Death certificate",
          "documentId": null,
          "externalHearingId": null,
          "workProduct": null,
          "caseType": "Original",
          "aod": false,
          "previousTaskAssignedOn": null,
          "placedOnHoldAt": null,
          "status": "assigned",
          "onHoldDuration": null,
          "instructions": [
              "dc"
          ],
          "decisionPreparedBy": null,
          "availableActions": [],
          "timelineTitle": "DeathCertificateMailTask completed",
          "hideFromQueueTableView": false,
          "hideFromTaskSnapshot": false,
          "hideFromCaseTimeline": false,
          "availableHearingLocations": [],
          "latestInformalHearingPresentationTask": {},
          "canMoveOnDocketSwitch": true,
          "timerEndsAt": null,
          "unscheduledHearingNotes": {},
          "ownedBy": "VLJ Support Staff",
          "daysSinceLastStatusChange": 0,
          "daysSinceBoardIntake": 0,
          "id": "3203",
          "claimant": {},
          "appeal_receipt_date": "2024-07-14"
      },
      "3205": {
          "uniqueId": "3205",
          "isLegacy": false,
          "type": "AddressChangeMailTask",
          "appealType": "Appeal",
          "addedByCssId": null,
          "appealId": 447,
          "externalAppealId": "0f6bb359-8624-4cef-8690-0891297f224f",
          "assignedOn": "2024-09-24T12:54:23.679-04:00",
          "closestRegionalOffice": null,
          "createdAt": "2024-09-24T12:54:23.679-04:00",
          "closedAt": null,
          "startedAt": null,
          "assigneeName": "Hearing Admin",
          "assignedTo": {
              "cssId": null,
              "name": "Hearing Admin",
              "id": 39,
              "isOrganization": true,
              "type": "HearingAdmin"
          },
          "assignedBy": {
              "firstName": "Jon",
              "lastName": "Admin",
              "cssId": "INBOUND_OPS_TEAM_ADMIN_USER",
              "pgId": 65
          },
          "completedBy": {
              "cssId": null
          },
          "cancelledBy": {
              "cssId": null
          },
          "cancelReason": null,
          "convertedBy": {
              "cssId": null
          },
          "convertedOn": null,
          "taskId": "3205",
          "parentId": 3204,
          "label": "Change of address",
          "documentId": null,
          "externalHearingId": null,
          "workProduct": null,
          "caseType": "Original",
          "aod": false,
          "previousTaskAssignedOn": null,
          "placedOnHoldAt": null,
          "status": "assigned",
          "onHoldDuration": null,
          "instructions": [
              "coa"
          ],
          "decisionPreparedBy": null,
          "availableActions": [],
          "timelineTitle": "AddressChangeMailTask completed",
          "hideFromQueueTableView": false,
          "hideFromTaskSnapshot": false,
          "hideFromCaseTimeline": false,
          "availableHearingLocations": [],
          "latestInformalHearingPresentationTask": {},
          "canMoveOnDocketSwitch": true,
          "timerEndsAt": null,
          "unscheduledHearingNotes": {},
          "ownedBy": "Hearing Admin",
          "daysSinceLastStatusChange": 0,
          "daysSinceBoardIntake": 0,
          "id": "3205",
          "claimant": {},
          "appeal_receipt_date": "2024-07-14"
      },
      "3207": {
          "uniqueId": "3207",
          "isLegacy": false,
          "type": "StatusInquiryMailTask",
          "appealType": "Appeal",
          "addedByCssId": null,
          "appealId": 447,
          "externalAppealId": "0f6bb359-8624-4cef-8690-0891297f224f",
          "assignedOn": "2024-09-24T12:54:23.721-04:00",
          "closestRegionalOffice": null,
          "createdAt": "2024-09-24T12:54:23.721-04:00",
          "closedAt": null,
          "startedAt": null,
          "assigneeName": "Litigation Support",
          "assignedTo": {
              "cssId": null,
              "name": "Litigation Support",
              "id": 18,
              "isOrganization": true,
              "type": "LitigationSupport"
          },
          "assignedBy": {
              "firstName": "Jon",
              "lastName": "Admin",
              "cssId": "INBOUND_OPS_TEAM_ADMIN_USER",
              "pgId": 65
          },
          "completedBy": {
              "cssId": null
          },
          "cancelledBy": {
              "cssId": null
          },
          "cancelReason": null,
          "convertedBy": {
              "cssId": null
          },
          "convertedOn": null,
          "taskId": "3207",
          "parentId": 3206,
          "label": "Status inquiry",
          "documentId": null,
          "externalHearingId": null,
          "workProduct": null,
          "caseType": "Original",
          "aod": false,
          "previousTaskAssignedOn": null,
          "placedOnHoldAt": null,
          "status": "assigned",
          "onHoldDuration": null,
          "instructions": [
              "si"
          ],
          "decisionPreparedBy": null,
          "availableActions": [],
          "timelineTitle": "StatusInquiryMailTask completed",
          "hideFromQueueTableView": false,
          "hideFromTaskSnapshot": false,
          "hideFromCaseTimeline": false,
          "availableHearingLocations": [],
          "latestInformalHearingPresentationTask": {},
          "canMoveOnDocketSwitch": true,
          "timerEndsAt": null,
          "unscheduledHearingNotes": {},
          "ownedBy": "Litigation Support",
          "daysSinceLastStatusChange": 0,
          "daysSinceBoardIntake": 0,
          "id": "3207",
          "claimant": {},
          "appeal_receipt_date": "2024-07-14"
      }
  })
    props.isInboundOpsUser = false;

    render(
      <Provider store={store}>
        <MemoryRouter>
          <Route>
            <CorrespondenceDetails {...props} />
          </Route>
        </MemoryRouter>
      </Provider>
    );
  });

  it('validates that save changes button is not present', () => {
    expect(screen.queryByText('Save changes')).not.toBeInTheDocument();
  });
});
