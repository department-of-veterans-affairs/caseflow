/* eslint-disable max-lines */

import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { Provider } from 'react-redux';
import CorrespondenceDetails from 'app/queue/correspondence/details/CorrespondenceDetails';
import {
  correspondenceDetailsData,
  correspondenceInfoData,
  prepareAppealForStoreData,
  veteranInformationData } from 'test/data/correspondence';
import { applyMiddleware, createStore } from 'redux';
import rootReducer from 'app/queue/reducers';
import COPY from '../../../../../COPY';
import thunk from 'redux-thunk';
import moment from 'moment';
import {
  prepareAppealForSearchStore,
  prepareAppealForStore,
  prepareTasksForStore,
  sortCaseTimelineEvents
} from 'app/queue/utils';
import { MemoryRouter, Route } from 'react-router-dom';
import { tasksUnrelatedToAnAppeal } from 'test/data/queue/taskActionModals/taskActionModalData';
import ApiUtil from 'app/util/ApiUtil';

jest.mock('redux', () => ({
  ...jest.requireActual('redux'),
  bindActionCreators: () => jest.fn().mockImplementation(() => Promise.resolve(true)),
}));

jest.mock('app/queue/utils', () => ({
  prepareAppealForSearchStore: jest.fn(),
  prepareAppealForStore: jest.fn(),
  prepareTasksForStore: jest.fn(),
  sortCaseTimelineEvents: jest.fn()
}));

jest.mock('app/queue/CaseListTable', () => () => (
  <div className="case-list-table">
    <table>
      <thead>
        <tr>
          <th></th>
          <th>Docket Number</th>
          <th>Appellant Name</th>
          <th>Status</th>
          <th>Types</th>
          <th>Number of Issues</th>
          <th>Decision Date</th>
          <th>Assigned To</th>
        </tr>
      </thead>
      <tbody>
        <tr key="0">
          <td><input type="checkbox" id="253" checked /></td>
          <td>240714-253</td>
          <td>John Doe</td>
          <td>Pending</td>
          <td>Original</td>
          <td>2</td>
          <td>2024-09-09</td>
          <td>Clerk of the Board</td>
        </tr>
        <tr key="1">
          <td><input type="checkbox" id="254" checked /></td>
          <td>240714-254</td>
          <td>Jane Smith</td>
          <td>Completed</td>
          <td>Evidence Submission</td>
          <td>3</td>
          <td>2024-02-02</td>
          <td>Mail</td>
        </tr>
      </tbody>
    </table>
  </div>
));

jest.spyOn(ApiUtil, 'post').mockImplementation(() => Promise.resolve(
  { params: {
    correspondence_uuid: {},
    priorMailIds: [1],
  } }
));

let initialState = {
  // correspondence: correspondenceDetailsData,
  correspondenceDetails: { ...correspondenceInfoData, ...veteranInformationData },
  prepareAppealForStoreData,
};

const store = createStore(rootReducer, initialState, applyMiddleware(thunk));

let props = {
  organizations: ['Inbound Ops Team'],
  isInboundOpsUser: true,
  updateCorrespondenceRelations: jest.fn(),
  correspondence: {
    uuid: '123',
    veteranFullName: 'John Doe',
    veteranFileNumber: '123456789',
    correspondenceType: 'Abeyance',
    nod: false,
    notes: 'Note Test',
    mailTasks: ['Task 1', 'Task 2'],
    all_correspondences: Array.from({ length: 30 }, (_, i) => ({ uuid: `uuid${i}`,
      vaDateOfReceipt: '2024-08-06T00:00:00Z',
      notes: `Note ${i}`,
      status: `Status ${i}` })),
    prior_mail: [
      { id: 1, vaDateOfReceipt: '2023-08-20T00:00:00Z' },
      { id: 2, vaDateOfReceipt: '2023-08-19T00:00:00Z' }
    ],
    relatedCorrespondenceIds: [2],
    tasksUnrelatedToAppeal: tasksUnrelatedToAnAppeal,
    correspondenceAppeals: [
      {
        id: 50,
        correspondencesAppealsTasks: [],
        docketNumber: '240714-252',
        veteranName: {
          id: 88,
          bgs_last_synced_at: null,
          closest_regional_office: null,
          created_at: '2024-07-15T16:47:17.658-04:00',
          date_of_death: null,
          date_of_death_reported_at: null,
          file_number: '550000017',
          first_name: 'John',
          last_name: 'Doe',
          middle_name: null,
          name_suffix: '88',
          participant_id: '650000017',
          ssn: '252858736',
          updated_at: '2024-07-15T16:47:17.658-04:00'
        },
        streamType: 'original',
        appealUuid: 'b36f1011-a34b-413b-a2b9-90fe0d8b2927',
        appealType: 'evidence_submission',
        numberOfIssues: 2,
        taskAddedData: { data: [] },
        status: 'Pending',
        assignedTo: null,
        correspondence: {
          id: 50,
          appeal_id: 252,
          correspondence_id: 322,
          created_at: '2024-08-14T10:53:47.213-04:00',
          updated_at: '2024-08-14T10:53:47.213-04:00'
        },
        appeal: {
          data: {
            id: 2392,
            type: 'appeal',
            attributes: {
              assigned_attorney: null,
              assigned_judge: null,
              appellant_hearing_email_recipient: null,
              representative_hearing_email_recipient: null,
              appellant_email_address: 'Bob.Smithkling@test.com',
              current_user_email: 'america@example.com',
              current_user_timezone: 'America/New_York',
              contested_claim: false,
              mst: null,
              pact: false,
              issues: [],
              status: 'not_distributed',
              decision_issues: [],
              substitute_appellant_claimant_options: [
                {
                  displayText: 'BOB VANCE, Spouse',
                  value: 'CLAIMANT_WITH_PVA_AS_VSO'
                },
                {
                  displayText: 'CATHY SMITH, Child',
                  value: '1129318238'
                },
                {
                  displayText: 'TOM BRADY, Child',
                  value: 'no-such-pid'
                }
              ],
              nod_date_updates: [],
              can_edit_request_issues: false,
              hearings: [],
              withdrawn: false,
              removed: false,
              overtime: false,
              veteran_appellant_deceased: false,
              assigned_to_location: 'Mail',
              distributed_to_a_judge: false,
              completed_hearing_on_previous_appeal: false,
              appellant_is_not_veteran: false,
              appellant_full_name: 'Bob Smithkling',
              appellant_first_name: 'Bob',
              appellant_middle_name: null,
              appellant_last_name: 'Smithkling',
              appellant_suffix: null,
              appellant_date_of_birth: '1994-09-10',
              appellant_address: {
                address_line_1: '9999 MISSION ST',
                address_line_2: 'UBER',
                address_line_3: 'APT 2',
                city: 'SAN FRANCISCO',
                zip: '94103',
                country: 'USA',
                state: 'CA'
              },
              appellant_phone_number: null,
              appellant_tz: 'America/Los_Angeles',
              appellant_relationship: 'Veteran',
              appellant_type: 'VeteranClaimant',
              appellant_party_type: null,
              unrecognized_appellant_id: null,
              has_poa: {
                id: 69,
                authzn_change_clmant_addrs_ind: null,
                authzn_poa_access_ind: null,
                claimant_participant_id: '650000069',
                created_at: '2024-09-10T14:24:18.372-04:00',
                file_number: '00001234',
                last_synced_at: '2024-09-10T14:24:18.372-04:00',
                legacy_poa_cd: '100',
                poa_participant_id: '600153863',
                representative_name: 'Clarence Darrow',
                representative_type: 'Attorney',
                updated_at: '2024-09-10T14:24:18.372-04:00'
              },
              cavc_remand: null,
              show_post_cavc_stream_msg: false,
              remand_source_appeal_id: null,
              remand_judge_name: null,
              appellant_substitution: null,
              substitutions: [],
              veteran_death_date: null,
              veteran_file_number: '550000069',
              veteran_participant_id: '650000069',
              efolder_link: 'https://vefs-claimevidence-ui-uat.stage.bip.va.gov',
              veteran_full_name: 'Bob Smithkling',
              closest_regional_office: null,
              closest_regional_office_label: null,
              available_hearing_locations: [],
              external_id: 'a175fdeb-4714-4f8e-8a31-35a983cdb590',
              type: 'Original',
              vacate_type: null,
              aod: false,
              docket_name: 'evidence_submission',
              docket_number: '240909-2392',
              docket_range_date: null,
              decision_date: null,
              nod_date: '2024-09-09',
              withdrawal_date: null,
              certification_date: null,
              paper_case: false,
              regional_office: null,
              caseflow_veteran_id: 180,
              document_id: null,
              attorney_case_review_id: null,
              attorney_case_rewrite_details: {
                note_from_attorney: null,
                untimely_evidence: null
              },
              can_edit_document_id: false,
              readable_hearing_request_type: null,
              readable_original_hearing_request_type: null,
              docket_switch: null,
              switched_dockets: [],
              has_notifications: false,
              cavc_remands_with_dashboard: 0,
              evidence_submission_task: {
                id: 18233,
                appeal_id: 2392,
                appeal_type: 'Appeal',
                assigned_at: '2024-09-10T14:24:18.454-04:00',
                assigned_by_id: null,
                assigned_to_id: 16,
                assigned_to_type: 'Organization',
                cancellation_reason: null,
                cancelled_by_id: null,
                closed_at: null,
                completed_by_id: null,
                created_at: '2024-09-10T14:24:18.454-04:00',
                instructions: [],
                parent_id: 18232,
                placed_on_hold_at: null,
                started_at: null,
                status: 'assigned',
                updated_at: '2024-09-10T14:24:18.454-04:00'
              },
              has_completed_sct_assign_task: false,
              waivable: false
            }
          }
        }
      },
      {
        id: 51,
        correspondencesAppealsTasks: [
          {
            id: 27,
            correspondence_appeal_id: 51,
            task_id: 3158,
            created_at: '2024-08-14T10:53:47.616-04:00',
            updated_at: '2024-08-14T10:53:47.616-04:00'
          }
        ],
        docketNumber: '240714-253',
        veteranName: {
          id: 88,
          bgs_last_synced_at: null,
          closest_regional_office: null,
          created_at: '2024-07-15T16:47:17.658-04:00',
          date_of_death: null,
          date_of_death_reported_at: null,
          file_number: '550000017',
          first_name: 'John',
          last_name: 'Doe',
          middle_name: null,
          name_suffix: '88',
          participant_id: '650000017',
          ssn: '252858736',
          updated_at: '2024-07-15T16:47:17.658-04:00'
        },
        streamType: 'original',
        appealUuid: 'a9b2523e-880d-4ef4-9f12-eae9d593631d',
        appealType: 'evidence_submission',
        numberOfIssues: 2,
        taskAddedData: { data: [
          {
            assigned_at: '2024-08-14T10:53:47.560-04:00',
            assigned_to: 'Hearing Admin',
            assigned_to_type: 'Organization',
            instructions: [
              'COA'
            ],
            type: 'Change of address'
          }
        ] },
        status: 'Pending',
        assignedTo: {
          id: 39,
          accepts_priority_pushed_cases: null,
          ama_only_push: false,
          ama_only_request: false,
          created_at: '2024-07-15T16:46:00.263-04:00',
          exclude_appeals_from_affinity: false,
          name: 'Hearing Admin',
          participant_id: null,
          role: null,
          status: 'active',
          status_updated_at: null,
          updated_at: '2024-07-15T16:46:00.263-04:00',
          url: 'hearing-admin'
        },
        correspondence: {
          id: 51,
          appeal_id: 253,
          correspondence_id: 322,
          created_at: '2024-08-14T10:53:47.217-04:00',
          updated_at: '2024-08-14T10:53:47.217-04:00'
        },
        appeal: {
          data: {
            id: 2392,
            type: 'appeal',
            attributes: {
              external_id: 'a9b2523e-880d-4ef4-9f12-eae9d593631d',
            }
          }
        }
      },
      {
        id: 52,
        correspondencesAppealsTasks: [
          {
            id: 1,
            correspondence_appeal_id: 52,
            task_id: 3160,
            created_at: '2024-08-14T10:53:47.678-04:00',
            updated_at: '2024-08-14T10:53:47.678-04:00'
          },
          {
            id: 29,
            correspondence_appeal_id: 52,
            task_id: 3162,
            created_at: '2024-08-14T10:53:47.733-04:00',
            updated_at: '2024-08-14T10:53:47.733-04:00'
          }
        ],
        docketNumber: '240714-254',
        veteranName: {
          id: 88,
          bgs_last_synced_at: null,
          closest_regional_office: null,
          created_at: '2024-07-15T16:47:17.658-04:00',
          date_of_death: null,
          date_of_death_reported_at: null,
          file_number: '550000017',
          first_name: 'John',
          last_name: 'Doe',
          middle_name: null,
          name_suffix: '88',
          participant_id: '650000017',
          ssn: '252858736',
          updated_at: '2024-07-15T16:47:17.658-04:00'
        },
        streamType: 'original',
        appealUuid: '7bd8281d-3b6e-442f-8e44-21b033f7049e',
        appealType: 'evidence_submission',
        numberOfIssues: 2,
        taskAddedData: { data: [
          {
            assigned_at: '2024-08-14T10:53:47.656-04:00',
            assigned_to: 'VLJ Support Staff',
            assigned_to_type: 'Organization',
            instructions: [
              'DC'
            ],
            type: 'Death certificate'
          },
          {
            assigned_at: '2024-08-14T10:53:47.716-04:00',
            assigned_to: 'Litigation Support',
            assigned_to_type: 'Organization',
            instructions: [
              'cong int'
            ],
            type: 'Congressional interest'
          }
        ] },
        status: 'Pending',
        assignedTo: {
          id: 8,
          accepts_priority_pushed_cases: null,
          ama_only_push: false,
          ama_only_request: false,
          created_at: '2024-07-15T16:45:56.066-04:00',
          exclude_appeals_from_affinity: false,
          name: 'VLJ Support Staff',
          participant_id: null,
          role: null,
          status: 'active',
          status_updated_at: null,
          updated_at: '2024-07-15T16:45:56.066-04:00',
          url: 'vlj-support'
        },
        correspondence: {
          id: 52,
          appeal_id: 254,
          correspondence_id: 322,
          created_at: '2024-08-14T10:53:47.221-04:00',
          updated_at: '2024-08-14T10:53:47.221-04:00'
        },
        appeal: {
          data: {
            id: 2392,
            type: 'appeal',
            attributes: {
              external_id: '7bd8281d-3b6e-442f-8e44-21b033f7049e',
            }
          }
        }
      }
    ],
    correspondenceAppealIds: [1, 2],

    appeals_information:
      [
        {
          id: 1,
          type: 'Correspondence',
          attributes: {
            assigned_to_location: 'Clerk of the Board',
            appellant_full_name: 'John Doe',
            type: 'Original',
            docket_number: '240714-253'
          }
        },
        {
          id: 2,
          type: 'Correspondence',
          attributes: {
            assigned_to_location: 'Mail',
            appellant_full_name: 'Jane Doe',
            type: 'Evidence',
            docket_number: '240714-254'
          }
        }
      ],
    claim_reviews: []
  }
};

describe('CorrespondenceDetails', () => {

  beforeEach(() => {
    store.dispatch = jest.fn();

    prepareAppealForSearchStore.mockReturnValue({
      appeals: {},
      appealDetails: {}
    });
    prepareAppealForStore.mockReturnValue({
      prepareAppealForStoreData
    });
    prepareTasksForStore.mockReturnValue({
      // mock return value
    });
    sortCaseTimelineEvents.mockReturnValue(
      tasksUnrelatedToAnAppeal
    );

    console.log(store.getState());

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
    const viewAllButton = screen.getAllByText('View all correspondence');

    fireEvent.click(viewAllButton[0]);
    expect(screen.getByText('Hide all correspondence')).toBeInTheDocument();
  });

  it('renders the component', () => {
    const userNameCount = screen.getAllByText('John Doe').length;

    expect(userNameCount).toBeGreaterThan(0);
    const packageDetailsTab = screen.getByText('Package Details');
    const associatedPriorMailTab = screen.getByText('Associated Prior Mail');
    const correspondenceAndAppealTasksTab = screen.getByText('Correspondence and Appeal Tasks');

    fireEvent.click(correspondenceAndAppealTasksTab);

    let collapsibleButtons = document.getElementsByClassName('plus-symbol');

    expect(collapsibleButtons.length).toBe(2);

    expect(screen.getByText('Veteran ID:')).toBeInTheDocument();
    expect(screen.getByText('Correspondence and Appeal Tasks')).toBeInTheDocument();
    expect(screen.getByText('Package Details')).toBeInTheDocument();
    expect(screen.getByText('Response Letters')).toBeInTheDocument();
    expect(screen.getByText('Associated Prior Mail')).toBeInTheDocument();
    expect(screen.getByText('View all correspondence')).toBeInTheDocument();
    expect(screen.getByText('Task not related to an Appeal')).toBeInTheDocument();
    expect(screen.getByText('Completed Mail Tasks')).toBeInTheDocument();
    expect(screen.getByText('Task 1')).toBeInTheDocument();
    expect(screen.getByText('Task 2')).toBeInTheDocument();

    // Existing Appeals Table and Columns
    fireEvent.click(collapsibleButtons[0]);

    expect(screen.getByText('Existing Appeals')).toBeInTheDocument();
    expect(screen.getByText('Appellant Name')).toBeInTheDocument();
    expect(screen.getByText('Status')).toBeInTheDocument();
    expect(screen.getByText('Types')).toBeInTheDocument();
    expect(screen.getByText('Number of Issues')).toBeInTheDocument();
    expect(screen.getByText('Decision Date')).toBeInTheDocument();
    expect(screen.getByText('Assigned To')).toBeInTheDocument();
    expect(screen.getByText('View veteran documents')).toBeInTheDocument();
    expect(screen.getByText('240714-253')).toBeInTheDocument();
    expect(screen.getByText('240714-254')).toBeInTheDocument();

    // Linked Appeals Sections
    expect(screen.queryByText('Tasks added to appeal')).not.toBeInTheDocument();

    expect(screen.queryByText('DOCKET NUMBER')).not.toBeInTheDocument();
    expect(screen.queryByText('APPELLANT NAME')).not.toBeInTheDocument();
    expect(screen.queryByText('APPEAL STREAM TYPE')).not.toBeInTheDocument();
    expect(screen.queryByText('NUMBER OF ISSUES')).not.toBeInTheDocument();
    expect(screen.queryByText('STATUS')).not.toBeInTheDocument();
    expect(screen.queryByText('ASSIGNED TO')).not.toBeInTheDocument();

    expect(document.getElementById('253')).toBeChecked();
    expect(document.getElementById('254')).toBeChecked();

    const linkedAppeal = document.getElementsByClassName('correspondence-existing-appeals');

    expect(linkedAppeal.length).toBe(2);

    expect(screen.getByText('240714-253')).toBeInTheDocument();
    expect(screen.getByText('240714-254')).toBeInTheDocument();
    expect(screen.getByText('Clerk of the Board')).toBeInTheDocument();
    expect(screen.getByText('Jane Smith')).toBeInTheDocument();

    // Clicks on the Package Details Tab and tests its expectations
    fireEvent.click(packageDetailsTab);
    expect(screen.getByText('Veteran Details')).toBeInTheDocument();
    expect(screen.getByText('John Doe')).toBeInTheDocument();
    expect(screen.getByText('Correspondence Type')).toBeInTheDocument();
    expect(screen.getByText('Package Document Type')).toBeInTheDocument();
    expect(screen.getByText('Non-NOD')).toBeInTheDocument();
    expect(screen.getByText('VA DOR')).toBeInTheDocument();
    expect(screen.getByText(moment(props.correspondence.vaDateOfReceipt).format('MM/DD/YYYY'))).toBeInTheDocument();
    expect(screen.getByText('Notes')).toBeInTheDocument();

    fireEvent.click(associatedPriorMailTab);
    expect(screen.getByText('Please select prior mail to link to this correspondence')).toBeInTheDocument();
    const priorDate = new Date(props.correspondence.prior_mail[0].vaDateOfReceipt);

    expect(screen.getByText(priorDate.toLocaleDateString('en-US'))).toBeInTheDocument();
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
    const saveChangesButton = screen.getByText('Save changes');

    const options = { params: {
      correspondence_uuid: props.correspondence.uuid,
      priorMailIds: [1]
    } };

    fireEvent.click(checkbox);

    ApiUtil.post.mockResolvedValueOnce({ options });

    fireEvent.click(saveChangesButton);

    await waitFor(() => {
      expect(screen.getByText('Changes were not successfully saved')).toBeInTheDocument();
      expect(screen.queryByText(COPY.CORRESPONDENCE_DETAILS.SAVE_CHANGES_BANNER.MESSAGE)).not.toBeInTheDocument();
    });
  });
});

describe('Correspondence details without beforeEach', () => {

  beforeEach(() => {
    store.dispatch = jest.fn();

    prepareAppealForSearchStore.mockReturnValue({
      appeals: {},
      appealDetails: {}
    });
    prepareAppealForStore.mockReturnValue({
      // mock return value
    });
    prepareTasksForStore.mockReturnValue({
      // mock return value
    });
    sortCaseTimelineEvents.mockReturnValue(
      tasksUnrelatedToAnAppeal
    );
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

/* eslint-enable max-lines */
