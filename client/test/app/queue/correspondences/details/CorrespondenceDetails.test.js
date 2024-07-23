import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom/extend-expect';
import { Provider } from 'react-redux';
import CorrespondenceDetails from 'app/queue/correspondence/details/CorrespondenceDetails';
import { correspondenceData } from 'test/data/correspondence';
import { applyMiddleware, createStore } from 'redux';
import rootReducer from 'app/queue/reducers';
import thunk from 'redux-thunk';

jest.mock('redux', () => ({
  ...jest.requireActual('redux'),
  bindActionCreators: () => jest.fn().mockImplementation(() => Promise.resolve(true)),
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
    correspondence: {
      veteranFullName: 'John Doe',
      veteranFileNumber: '123456789',
      mailTasks: ['Task 1', 'Task 2']
    }
  };

  beforeEach(() => {
    store.dispatch = jest.fn();
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
  });

  it('displays the correspondence tasks correctly', () => {
        render(
            <Provider store={store}>
                <CorrespondenceDetails {...props} />
            </Provider>
        );

        expect(screen.getByText('Completed Mail Tasks')).toBeInTheDocument();
        expect(screen.getByText('Task 1')).toBeInTheDocument();
        expect(screen.getByText('Task 2')).toBeInTheDocument();
    });

  it('renders correspondenceTasks correctly', () => {
    render(
      <Provider store={store}>
        <CorrespondenceDetails {...props} />
      </Provider>
    );

    // Check if the header and AppSegment are rendered correctly
    expect(screen.getByText('Existing Appeals')).toBeInTheDocument();

    // Check if the CaseListTable is rendered correctly using class name
    const caseListTable = screen.getByRole('table');

    expect(caseListTable).toBeInTheDocument();

    // Check if table columns are rendered correctly
    const headers = ['Docket Number',
      'Appellant Name',
      'Appeal Status',
      'Appeal Type',
      'Number of Issues',
      'Decision Date',
      'Appeal Location'
    ];

    headers.forEach((header) => {
      expect(screen.getByText(header)).toBeInTheDocument();
    });
  });

});
