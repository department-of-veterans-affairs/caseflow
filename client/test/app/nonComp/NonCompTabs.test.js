import React from 'react';
import { render, screen } from '@testing-library/react';
import { Provider } from 'react-redux';
import { createStore } from 'redux';
import '@testing-library/jest-dom';

import { taskFilterDetails } from '../../data/taskFilterDetails';
import NonCompTabsUnconnected from 'app/nonComp/components/NonCompTabs';

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
});

const createReducer = (storeValues) => {
  return function (state = storeValues) {

    return state;
  };
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
  });

  it('renders a tab titled "Completed tasks"', () => {

    expect(screen.getAllByText('Completed tasks')).toBeTruthy();
  });

});
