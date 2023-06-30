import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import { Provider } from 'react-redux';
import { createStore } from 'redux';
import '@testing-library/jest-dom';

import { taskFilterDetails } from '../../data/taskFilterDetails';
import NonCompTabsUnconnected from 'app/nonComp/components/NonCompTabs';
import ApiUtil from '../../../app/util/ApiUtil';

const basicProps = {
  businessLine: 'Veterans Health Administration',
  businessLineUrl: 'vha',
  baseTasksUrl: '/decision_reviews/vha',
  selectedTask: null,
  decisionIssuesStatus: {},
  taskFilterDetails,
  featureToggles: {
    decisionReviewQueueSsnColumn: true
  },
};

beforeEach(() => {
  jest.clearAllMocks();

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

const renderNonCompTabs = () => {

  const nonCompTabsReducer = createReducer(basicProps);

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

describe('NonCompTabs', () => {
  beforeEach(() => {
    renderNonCompTabs(basicProps);
  });

  it('renders a tab titled "In progress tasks"', () => {

    expect(screen.getAllByText('In progress tasks')).toBeTruthy();

    // Check for the correct in progress tasks header values
    const expectedHeaders = ['Claimant', 'Veteran SSN', 'Issues', 'Issue Type', 'Days Waiting', 'Type'];
    const sortableHeaders = expectedHeaders.filter((header) => header !== 'Type');
    const filterableHeaders = ['type', 'issue type'];

    checkTableHeaders(expectedHeaders);
    checkSortableHeaders(sortableHeaders);
    checkFilterableHeaders(filterableHeaders);

  });

  it('renders a tab titled "Completed tasks"', async () => {

    expect(screen.getAllByText('Completed tasks')).toBeTruthy();

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
