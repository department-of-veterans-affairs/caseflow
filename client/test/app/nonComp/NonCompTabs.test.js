import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { Provider } from 'react-redux';
import { createStore } from 'redux';
import '@testing-library/jest-dom';

import { taskFilterDetails } from '../../data/taskFilterDetails';
import { NonCompTabsUnconnected } from 'app/nonComp/components/NonCompTabs';
import { BrowserRouter as Router } from 'react-router-dom';
import { HeaderRow } from '../../../app/queue/QueueTable';
import { DoubleArrowIcon } from '../../../app/components/icons/DoubleArrowIcon';

const basicProps = {
  businessLine: 'Veterans Health Administration',
  businessLineUrl: 'vha',
  baseTasksUrl: '/decision_reviews/vha',
  selectedTask: null,
  decisionIssuesStatus: { },
  taskFilterDetails
};

beforeEach(() => {
  jest.clearAllMocks();
});

afterEach(() => {
  jest.clearAllMocks();
});

const createReducer = (storeValues) => {
  return function (state = storeValues) {
    return state;
  };
};

const renderNonCompTabs = (state) => {
  const nonCompTabsReducer = createReducer(state);
  const props = {
    currentTab: '',
    dispatch: '',
    baseTasksUrl: '',
    taskFilterDetails: {
      in_progress: {},
      completed: {}
    } };

  const store = createStore(nonCompTabsReducer);

  return render(
    <Provider store={store}>
      <Router>
        <NonCompTabsUnconnected {...props} />
      </Router>
    </Provider>
  );
};

describe('NonCompTabs', () => {
  beforeEach(() => {
    renderNonCompTabs(basicProps);
  });

  it('renders a tab titled "In progress tasks"', () => {

    expect(screen.getAllByText('In progress tasks')).toBeTruthy();
  });

  it('renders a tab titled "Completed tasks"', () => {

    expect(screen.getAllByText('Completed tasks')).toBeTruthy();
  });

});

describe('In progress tasks tab columns', () => {
  beforeEach(() => {
    renderNonCompTabs(basicProps);
  });

  it('renders 5 columns', () => {
    render(<HeaderRow />);
    const headerCount = screen.getAllByRole('generic');

    expect(headerCount.length).toEqual(5);
  });

  it('renders Claimant column', () => {
    expect(screen.getAllByText('Claimant')).toBeTruthy();
  });

  // it('Claimant column filters rows in ascending order', () => {
  //   //TODO expect().toBe();
  // });

  // it('Claimant column filters rows in descending order', () => {
  //   //TODO expect().toBe();
  // });

  it('Claimant column changes url when clicked (asc)', () => {
    const handleClick = jest.fn();

    render(
      <DoubleArrowIcon onClick={handleClick}>Claimant</DoubleArrowIcon>);
    fireEvent.click(screen.queryAllByText);
    // valuefunction:(task) and getSortValue:(task) is where url is being set
    expect(global.window.location.href).toContain(
      '/decision_reviews/vha?tab=in_progress&page=1&sort_by=claimantColumn&order=asc');
  });

  it('Claimant column changes url when clicked (desc)', () => {
    expect(global.window.location.href).toContain(
      '/decision_reviews/vha?tab=in_progress&page=1&sort_by=claimantColumn&order=desc');
  });

  it('renders Veteran Participant Id column', () => {
    expect(screen.getAllByText('Veteran Participant Id')).toBeTruthy();
  });

  // it('Veteran Participant Id column filters rows in ascending order', () => {
  //   //TODO expect().toBe();
  // });

  // it('Veteran Participant Id column filters rows in descending order', () => {
  //   //TODO expect().toBe();
  // });

  it('Veteran Participant Id column changes url when clicked (asc)', () => {
    expect(global.window.location.href).toContain(
      '/decision_reviews/vha?tab=in_progress&page=1&sort_by=veteranParticipantIdColumn&order=asc');
  });

  it('Veteran Participant Id column changes url when clicked (desc)', () => {
    expect(global.window.location.href).toContain(
      '/decision_reviews/vha?tab=in_progress&page=1&sort_by=veteranParticipantIdColumn&order=desc');
  });

  it('renders Issues column', () => {
    expect(screen.getAllByText('Issues')).toBeTruthy();
  });

  // it('Issues column filters rows in ascending order', () => {
  //   //TODO expect().toBe();
  // });

  // it('Issues column filters rows in descending order', () => {
  //   //TODO expect().toBe();
  // });

  it('Issues column changes url when clicked (asc)', () => {
    expect(global.window.location.href).toContain(
      'http://localhost:3000/decision_reviews/vha?tab=in_progress&page=1&sort_by=issueCountColumn&order=asc');
  });

  it('Issues column changes url when clicked (desc)', () => {
    expect(global.window.location.href).toContain(
      'http://localhost:3000/decision_reviews/vha?tab=in_progress&page=1&sort_by=issueCountColumn&order=desc');
  });

  it('renders Days Waiting column', () => {
    expect(screen.getAllByText('Days Waiting')).toBeTruthy();
  });

  // it('Days Waiting column filters rows in ascending order', () => {
  //   //TODO expect().toBe();
  // });

  // it('Days Waiting column filters rows in descending order', () => {
  //   //TODO expect().toBe();
  // });

  it('Days Waiting column changes url when clicked (asc)', () => {
    expect(global.window.location.href).toContain(
      '/decision_reviews/vha?tab=in_progress&page=1&sort_by=daysWaitingColumn&order=asc');
  });

  it('Days Waiting column changes url when clicked (desc)', () => {
    expect(global.window.location.href).toContain(
      '/decision_reviews/vha?tab=in_progress&page=1&sort_by=daysWaitingColumn&order=desc');
  });

});

describe('Completed tasks columns', () => {
  beforeEach(() => {
    renderNonCompTabs(basicProps);
  });

  it('renders 5 columns', () => {
    render(<HeaderRow />);
    const headerCount = screen.getAllByRole('generic');

    expect(headerCount.length).toEqual(5);
  });

  it('renders Claimant column', () => {
    expect(screen.getAllByText('Claimant')).toBeTruthy();
  });

  // it('Claimant column filters rows in ascending order', () => {
  //   //TODO expect().toBe();
  // });

  // it('Claimant column filters rows in descending order', () => {
  //   //TODO expect().toBe();
  // });

  it('Claimant column changes url when clicked (asc)', () => {
    expect(global.window.location.href).toContain(
      '/decision_reviews/vha?tab=completed&page=1&sort_by=claimantColumn&order=asc');
  });

  it('Claimant column changes url when clicked (desc)', () => {
    expect(global.window.location.href).toContain(
      '/decision_reviews/vha?tab=completed&page=1&sort_by=claimantColumn&order=desc');
  });

  it('renders Veteran Participant Id column', () => {
    expect(screen.getAllByText('Veteran Participant Id')).toBeTruthy();
  });

  // it('Veteran Participant Id column filters rows in ascending order', () => {
  //   //TODO expect().toBe();
  // });

  // it('Veteran Participant Id column filters rows in descending order', () => {
  //   //TODO expect().toBe();
  // });

  it('Veteran Participant Id column changes url when clicked (asc)', () => {
    expect(global.window.location.href).toContain(
      '/decision_reviews/vha?tab=completed&page=1&sort_by=veteranParticipantIdColumn&order=asc');
  });

  it('Veteran Participant Id column changes url when clicked (desc)', () => {
    expect(global.window.location.href).toContain(
      '/decision_reviews/vha?tab=completed&page=1&sort_by=veteranParticipantIdColumn&order=desc');
  });

  it('renders Issues column', () => {
    expect(screen.getAllByText('Issues')).toBeTruthy();
  });

  // it('Issues column filters rows in ascending order', () => {
  //   //TODO expect().toBe();
  // });

  // it('Issues column filters rows in descending order', () => {
  //   //TODO expect().toBe();
  // });

  it('Issues column changes url when clicked (asc)', () => {
    expect(global.window.location.href).toContain(
      '/decision_reviews/vha?tab=completed&page=1&sort_by=issueCountColumn&order=asc');
  });

  it('Issues column changes url when clicked (desc)', () => {
    expect(global.window.location.href).toContain(
      '/decision_reviews/vha?tab=completed&page=1&sort_by=issueCountColumn&order=desc');
  });

  it('renders Date Completed column', () => {
    expect(screen.getAllByText('Date Completed')).toBeTruthy();
  });

  // it('Date Completed column filters rows in ascending order', () => {
  //   //TODO expect().toBe();
  // });

  // it('Date Completed column filters rows in descending order', () => {
  //   //TODO expect().toBe();
  // });

  it('Date Completed column changes url when clicked (asc)', () => {
    expect(global.window.location.href).toContain(
      '/decision_reviews/vha?tab=completed&page=1&sort_by=completedDateColumn&order=asc');
  });

  it('Date Completed column changes url when clicked (desc)', () => {
    expect(global.window.location.href).toContain(
      '/decision_reviews/vha?tab=completed&page=1&sort_by=completedDateColumn&order=desc');
  });

});
