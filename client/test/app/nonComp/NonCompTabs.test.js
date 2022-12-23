import React from 'react';
import { render, screen } from '@testing-library/react';
import { Provider } from 'react-redux';
import { createStore } from 'redux';
import '@testing-library/jest-dom';
import NonCompTabsUnconnected from 'app/nonComp/components/NonCompTabs';

const basicProps = {
  businessLine: 'Veterans Health Administration',
  businessLineUrl: 'vha',
  baseTasksUrl: '/decision_reviews/vha',
  selectedTask: null,
  decisionIssuesStatus: { },
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

beforeEach(() => {
  renderNonCompTabs();
});

afterEach(() => {
  jest.clearAllMocks();
});

describe('NonCompTabs', () => {
  it('renders a tab titled "In progress tasks"', () => {

    renderNonCompTabs(basicProps);

    expect(screen.getAllByText('In progress tasks')).toBeTruthy();
  });

  it('renders a tab titled "Completed tasks"', () => {

    renderNonCompTabs(basicProps);

    expect(screen.getAllByText('Completed tasks')).toBeTruthy();
  });

});
