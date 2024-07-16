import React from 'react';
import CaseDistributionApp from 'app/caseDistribution/pages/CaseDistributionApp';
import {
  history as leverHistory,
  mockAffinityDaysLevers,
  mockBatchLevers,
  mockDocketDistributionPriorLevers,
  mockDocketTimeGoalsLevers,
  mockStaticLevers
} from '../../data/adminCaseDistributionLevers';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { mount } from 'enzyme';
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

  it('renders Case Distribution App', () => {
    const store = getStore();

    let wrapper = mount(
      <Provider store={store}>
        <CaseDistributionApp
          acdLeversForStore={testLevers}
          acd_levers={testLevers}
          acd_history={leverHistory}
          user_is_an_acd_admin
        />
      </Provider>
    );

    wrapper.update();

    expect(wrapper.find('#lever-history-table').exists()).toBeTruthy();
    expect(wrapper.find('.inactive-data-content').exists()).toBeTruthy();
    expect(wrapper.find('.lever-content').exists()).toBeTruthy();
  });

  it('matches snapshot', () => {
    const store = getStore();

    const { container } = render(
      <Provider store={store}>
        <CaseDistributionApp
          acdLeversForStore={testLevers}
          acd_levers={testLevers}
          acd_history={leverHistory}
          user_is_an_acd_admin
        />
      </Provider>
    );

    expect(container).toMatchSnapshot();
  });
});

