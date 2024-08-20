import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom/extend-expect';
import { Provider } from 'react-redux';
import CorrespondenceDetails from 'app/queue/correspondence/details/CorrespondenceDetails';
import { correspondenceData } from 'test/data/correspondence';
import { applyMiddleware, createStore } from 'redux';
import rootReducer from 'app/queue/reducers';
import thunk from 'redux-thunk';
import { prepareAppealForSearchStore, sortCaseTimelineEvents } from 'app/queue/utils';
import { debug } from 'console';

jest.mock('redux', () => ({
  ...jest.requireActual('redux'),
  bindActionCreators: () => jest.fn().mockImplementation(() => Promise.resolve(true)),
}));
jest.mock('app/queue/utils', () => ({
  prepareAppealForSearchStore: jest.fn(),
  sortCaseTimelineEvents: jest.fn()
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
            <td>{'John Doe'}</td>
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

let initialState = {
  correspondence: correspondenceData
};
const store = createStore(rootReducer, initialState, applyMiddleware(thunk));

describe('CorrespondenceDetails', () => {
  const props = {
    organizations: ['Inbound Ops Team'],
    correspondence: {
      veteranFullName: 'John Doe',
      veteranFileNumber: '123456789',
      mailTasks: ['Task 1', 'Task 2'],
      tasksUnrelatedToAppeal: [{
        type: 'FOIA request',
        assigned_to: 'CAVC Litigation Support',
        assigned_at: '07/23/2024',
        instructions: [
          'cavc'
        ],
        assigned_to_type: 'Organization'
      },
      {
        type: 'Cavc request',
        assigned_to: 'CAVC Litigation Support',
        assigned_at: '07/23/2024',
        instructions: [
          'other cavc'
        ],
        assigned_to_type: 'Organization'
      }],
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
          taskAddedData: [],
          status: 'Pending',
          assignedTo: null,
          correspondence: {
            id: 50,
            appeal_id: 252,
            correspondence_id: 322,
            created_at: '2024-08-14T10:53:47.213-04:00',
            updated_at: '2024-08-14T10:53:47.213-04:00'
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
          taskAddedData: [
            {
              assigned_at: '2024-08-14T10:53:47.560-04:00',
              assigned_to: 'Hearing Admin',
              assigned_to_type: 'Organization',
              instructions: [
                'COA'
              ],
              type: 'Change of address'
            }
          ],
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
          }
        },
        {
          id: 52,
          correspondencesAppealsTasks: [
            {
              id: 28,
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
          taskAddedData: [
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
          ],
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
          }
        }
      ],

      appeals_information: {
        appeals: [
          {
            id: 1,
            type: 'appeal',
            attributes: {
              assigned_to_location: 'Mail',
              appellant_full_name: 'John Doe',
              type: 'Original',
              docket_number: '123-456'
            }
          }
        ],
        claim_reviews: []
      }
    }
  };

  beforeEach(() => {
    store.dispatch = jest.fn();

    prepareAppealForSearchStore.mockReturnValue({
      appeals: {},
      appealDetails: {}
    });
    sortCaseTimelineEvents.mockReturnValue(
      [{
        assignedOn: '07/23/2024',
        assignedTo: 'Litigation Support',
        label: 'Status inquiry',
        instructions: [
          'stat inq'
        ],
        availableActions: []
      }]
    );

  });

  it('renders the component', () => {
    render(
      <Provider store={store}>
        <CorrespondenceDetails {...props} />
      </Provider>
    );
    // debug();

    expect(screen.getByText('John Doe')).toBeInTheDocument();
    expect(screen.getByText('Veteran ID:')).toBeInTheDocument();
    expect(screen.getByText('Correspondence and Appeal Tasks')).toBeInTheDocument();
    expect(screen.getByText('Package Details')).toBeInTheDocument();
    expect(screen.getByText('Response Letters')).toBeInTheDocument();
    expect(screen.getByText('Associated Prior Mail')).toBeInTheDocument();

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
  });
});
