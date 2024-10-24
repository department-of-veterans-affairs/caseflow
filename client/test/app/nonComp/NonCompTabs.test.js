import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import { Provider } from 'react-redux';
import { createStore } from 'redux';
import '@testing-library/jest-dom';

import { vhaTaskFilterDetails, genericTaskFilterDetails } from '../../data/taskFilterDetails';
import NonCompTabsUnconnected from 'app/nonComp/components/NonCompTabs';
import ApiUtil from '../../../app/util/ApiUtil';
import { VHA_INCOMPLETE_TAB_DESCRIPTION, VHA_PENDING_REQUESTS_TAB_DESCRIPTION } from '../../../COPY';

const basicVhaProps = {
  businessLine: 'Veterans Health Administration',
  businessLineUrl: 'vha',
  baseTasksUrl: '/decision_reviews/vha',
  selectedTask: null,
  decisionIssuesStatus: {},
  taskFilterDetails: vhaTaskFilterDetails,
  featureToggles: {
    decisionReviewQueueSsnColumn: true
  },
  businessLineConfig: {
    tabs: ['incomplete', 'pending', 'in_progress', 'completed']
  },
};

const basicGenericProps = {
  businessLine: 'Generic',
  businessLineUrl: 'generic',
  baseTasksUrl: '/decision_reviews/generic',
  selectedTask: null,
  decisionIssuesStatus: {},
  taskFilterDetails: genericTaskFilterDetails,
  featureToggles: {
    decisionReviewQueueSsnColumn: true
  },
  businessLineConfig: {
    tabs: ['in_progress', 'completed']
  },
};

beforeEach(() => {
  // jest.clearAllMocks();

  // Mock ApiUtil get so the tasks will appear in the queues.
  ApiUtil.get = jest.fn().mockResolvedValue({
    tasks: { data: [] },
    tasks_per_page: 15,
    task_page_count: 3,
    total_task_count: 44
  });
});

const createReducer = (storeValues) => {
  return function (state = storeValues) {

    return state;
  };
};

const checkTableHeaders = (expectedHeaders) => {
  const columnHeaders = screen.getAllByRole('columnheader');

  expect(columnHeaders).toHaveLength(expectedHeaders.length);

  columnHeaders.forEach((header, index) => {
    const span = header.querySelector('span > span');

    expect(span.textContent).toBe(expectedHeaders[index]);
  });
};

const checkSortableHeaders = (expectedHeaders) => {
  expectedHeaders.forEach((header) => {
    expect(screen.getByLabelText(`Sort by ${header}`)).toBeInTheDocument();
  });
};

const checkFilterableHeaders = (expectedHeaders) => {
  expectedHeaders.forEach((header) => {
    expect(screen.getByLabelText(`Filter by ${header}`)).toBeInTheDocument();
  });
};

const renderNonCompTabs = (props) => {

  const nonCompTabsReducer = createReducer({ nonComp: props });

  const store = createStore(nonCompTabsReducer);

  return render(
    <Provider store={store}>
      <NonCompTabsUnconnected />
    </Provider>
  );
};

afterEach(() => {
  jest.clearAllMocks();
});

describe('NonCompTabsVha', () => {
  beforeEach(() => {
    renderNonCompTabs(basicVhaProps);
  });

  it('renders a tab titled "In Progress Tasks"', () => {
    expect(screen.getAllByText('In Progress Tasks (410)')).toBeTruthy();

    // Check for the correct in progress tasks header values
    const expectedHeaders = ['Claimant', 'Veteran SSN', 'Issues', 'Issue Type', 'Days Waiting', 'Type'];
    const sortableHeaders = expectedHeaders.filter((header) => header !== 'Type');
    const filterableHeaders = ['type', 'issue type'];

    checkTableHeaders(expectedHeaders);
    checkSortableHeaders(sortableHeaders);
    checkFilterableHeaders(filterableHeaders);

  });

  it('renders a tab titled "Pending tasks"', async () => {
    expect(screen.getAllByText('Pending Tasks (0)')).toBeTruthy();

    const tabs = screen.getAllByRole('tab');

    await tabs[1].click();

    await waitFor(() => {
      expect(screen.getByText(VHA_PENDING_REQUESTS_TAB_DESCRIPTION)).toBeInTheDocument();
    });

    // Check for the correct pending tasks header values
    const expectedHeaders = ['Claimant',
      'Veteran SSN',
      'Issues',
      'Issue Type',
      'Pending Requests',
      'Days Waiting',
      'Type'];
    const sortableHeaders = expectedHeaders.filter((header) => header !== 'Type');
    const filterableHeaders = ['type', 'issue type'];

    checkTableHeaders(expectedHeaders);
    checkSortableHeaders(sortableHeaders);
    checkFilterableHeaders(filterableHeaders);

  });

  it('renders a tab titled "Incomplete tasks"', async () => {
    expect(screen.getAllByText('Incomplete Tasks (0)')).toBeTruthy();

    const tabs = screen.getAllByRole('tab');

    await tabs[0].click();

    await waitFor(() => {
      expect(screen.getByText(VHA_INCOMPLETE_TAB_DESCRIPTION)).toBeInTheDocument();
    });

    // Check for the correct incomplete tasks header values
    const expectedHeaders = ['Claimant', 'Veteran SSN', 'Issues', 'Issue Type', 'Days Waiting', 'Type'];
    const sortableHeaders = expectedHeaders.filter((header) => header !== 'Type');
    const filterableHeaders = ['type', 'issue type'];

    checkTableHeaders(expectedHeaders);
    checkSortableHeaders(sortableHeaders);
    checkFilterableHeaders(filterableHeaders);

  });

  it('renders a tab titled "Completed tasks"', async () => {

    expect(screen.getAllByText('Completed Tasks')).toBeTruthy();

    const tabs = screen.getAllByRole('tab');

    await tabs[3].click();

    await waitFor(() => {
      // expect(screen.getByText('Cases completed (last 7 days):')).toBeInTheDocument();
      expect(screen.getByText('Cases completed:')).toBeInTheDocument();
    });

    // Check for the correct completed tasks header values
    const expectedHeaders = ['Claimant', 'Veteran SSN', 'Issues', 'Issue Type', 'Date Completed', 'Type'];
    const sortableHeaders = expectedHeaders.filter((header) => header !== 'Type');
    const filterableHeaders = ['type', 'issue type'];

    checkTableHeaders(expectedHeaders);
    checkSortableHeaders(sortableHeaders);
    checkFilterableHeaders(filterableHeaders);

  });
});

describe('NonCompTabsGeneric', () => {
  beforeEach(() => {
    renderNonCompTabs(basicGenericProps);
  });

  it('renders a tab titled "In progress tasks"', async () => {
    expect(screen.getAllByText('In Progress Tasks (0)')).toBeTruthy();

    const tabs = screen.getAllByRole('tab');

    // The async from the first describe block is interferring with this test so wait for the tab to reload apparently.
    await tabs[0].click();
    await waitFor(() => {
      expect(screen.getByText('Days Waiting')).toBeInTheDocument();
    });

    // Check for the correct in progress tasks header values
    const expectedHeaders = ['Claimant', 'Veteran SSN', 'Issues', 'Issue Type', 'Days Waiting', 'Type'];
    const sortableHeaders = expectedHeaders.filter((header) => header !== 'Type');
    const filterableHeaders = ['type', 'issue type'];

    checkTableHeaders(expectedHeaders);
    checkSortableHeaders(sortableHeaders);
    checkFilterableHeaders(filterableHeaders);

  });

  it('does not render a tab titled "Incomplete tasks"', () => {
    expect(screen.queryByText('Incomplete Tasks (0)')).toBeNull();
  });

  it('does not render a tab titled "Pending tasks"', () => {
    expect(screen.queryByText('Pending Tasks (0)')).toBeNull();
  });

  it('renders a tab titled "Completed tasks"', async () => {

    expect(screen.getAllByText('Completed Tasks')).toBeTruthy();

    const tabs = screen.getAllByRole('tab');

    await tabs[1].click();

    await waitFor(() => {
      expect(screen.getByText('Cases completed (last 7 days):')).toBeInTheDocument();
    });

    // Check for the correct completed tasks header values
    const expectedHeaders = ['Claimant', 'Veteran SSN', 'Issues', 'Issue Type', 'Date Completed', 'Type'];
    const sortableHeaders = expectedHeaders.filter((header) => header !== 'Type');
    const filterableHeaders = ['type', 'issue type'];

    checkTableHeaders(expectedHeaders);
    checkSortableHeaders(sortableHeaders);
    checkFilterableHeaders(filterableHeaders);

  });
});
