import React from 'react';
import CaseDistributionApp from 'app/caseDistribution/pages/CaseDistributionApp';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { mount } from 'enzyme';

describe('render Case Distribution Application', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  let testLevers = {
    static: [],
    batch: [],
    affinity: [],
    docket_distribution_prior: [],
    docket_time_goal: []
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
          acd_history={[]}
          user_is_an_acd_admin
        />
      </Provider>
    );

    wrapper.update();

    expect(wrapper.find('#lever-history-table').exists()).toBeTruthy();
    expect(wrapper.find('.inactive-data-content').exists()).toBeTruthy();
    expect(wrapper.find('.lever-content').exists()).toBeTruthy();
  });

});

