import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom/extend-expect';
import { Provider } from 'react-redux';
import CorrespondenceDetails from 'app/queue/correspondence/details/CorrespondenceDetails';
import { correspondenceData } from 'test/data/correspondence';
import { applyMiddleware, createStore } from 'redux';
import rootReducer from 'app/queue/reducers';
import thunk from 'redux-thunk';
import moment from 'moment';
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
      correspondenceType: 'Abeyance',
      nod: false,
      notes: 'Note Test',
      mailTasks: ['Task 1', 'Task 2'],
      all_correspondences: Array.from({ length: 30 }, (_, i) => ({ uuid: `uuid${i}`, vaDateOfReceipt: '2024-08-06T00:00:00Z', notes: `Note ${i}`, status: `Status ${i}` })),
      tasksUnrelatedToAppeal: [{
        type: 'FOIA request',
        label: 'Other Motion',
        status: 'assigned',
        uniqueId: 3080,
        assigned_to: 'CAVC Litigation Support',
        assigned_at: '07/23/2024',
        instructions: [
          'cavc'
        ],
        assigned_to_type: 'Organization'
      },
      {
        type: 'Cavc request',
        label: 'CAVC Task',
        status: 'assigned',
        uniqueId: 3080,
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
            type: 'Correspondence',
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

  test('toggles view all correspondence', () => {
    render(
      <Provider store={store}>
        <CorrespondenceDetails {...props} />
      </Provider>
    );
    const viewAllButton = screen.getByText('View all correspondence');

    fireEvent.click(viewAllButton);
    expect(screen.getByText('Hide all correspondence')).toBeInTheDocument();
  });

  it('renders the component', () => {
    render(
      <Provider store={store}>
        <CorrespondenceDetails {...props} />
      </Provider>
    );

    // const correspondenceAndAppealTasksTab = screen.getByText('Correspondence and Appeal Tasks');
    const packageDetailsTab = screen.getByText('Package Details');
    // const responseLettersTab = screen.getByText('Response Letters');
    // const associatedPriorMailTab = screen.getByText('Associated Prior Mail');

    expect(screen.getByText('John Doe')).toBeInTheDocument();
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
  });
});