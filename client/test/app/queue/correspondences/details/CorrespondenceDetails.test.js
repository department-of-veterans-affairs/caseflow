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
            <td>{appeal.appellantFullName}</td>
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
        "assignedOn": "07/23/2024",
        "assignedTo": "Litigation Support",
        "label": "Status inquiry",
        "instructions": [
            "stat inq"
        ],
        "availableActions": []
    }]
    )

  });

  it('renders the component', () => {
    render(
      <Provider store={store}>
        <CorrespondenceDetails {...props} />
      </Provider>
    );

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
  })});
