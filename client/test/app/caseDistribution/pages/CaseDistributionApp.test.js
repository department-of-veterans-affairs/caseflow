import React from 'react';
import CaseDistributionApp from 'app/caseDistribution/pages/CaseDistributionApp';
import {
  history as leverHistory,
  mockAffinityDaysLevers,
  mockBatchLevers,
  mockDocketDistributionPriorLevers,
  mockDocketTimeGoalsLevers,
  mockStaticLevers
} from '../../../data/adminCaseDistributionLevers';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { render } from '@testing-library/react';


describe('render Case Distribution Application', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  let testLevers = {
    static: mockStaticLevers,
    batch: mockBatchLevers,
    affinity: mockAffinityDaysLevers,
    docket_distribution_prior: mockDocketDistributionPriorLevers,
    docket_time_goal: mockDocketTimeGoalsLevers
  };

  afterEach(() => {
    jest.clearAllMocks();
  });

  it.only('renders Case Distribution App', () => {
    const store = getStore();

    const {container} = render(
      <Provider store={store}>
        <CaseDistributionApp
          acdLeversForStore={testLevers}
          acd_levers={testLevers}
          acd_history={leverHistory}
          user_is_an_acd_admin
        />
      </Provider>
    );

    // Assertions
    expect(container.querySelector('#lever-history-table')).toBeInTheDocument();
    expect(container.querySelector('.inactive-data-content')).toBeInTheDocument();
    expect(container.querySelector('.lever-content')).toBeInTheDocument();
  });
});

