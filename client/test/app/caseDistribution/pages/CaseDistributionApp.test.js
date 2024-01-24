import React from 'react';
import CaseDistributionApp from 'app/caseDistribution/pages/CaseDistributionApp';
import CaseDistributionContent from 'app/caseDistribution/components/CaseDistributionContent';
import { connect, Provider } from 'react-redux';
import { bindActionCreators, createStore, applyMiddleware } from 'redux';
import { render, waitFor } from '@testing-library/react';

import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { testingdocketDistributionPriorLevers } from '../../../data/adminCaseDistributionLevers';
import { mount } from 'enzyme';

describe('render Case Distribution App', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  let testLevers = {
    static: [],
    batch: [],
    affinity: [],
    docket_distribution_prior: testingdocketDistributionPriorLevers,
    docket_time_goal: []
  };

  afterEach(() => {
    jest.clearAllMocks();
  });

  beforeEach(() => {
    jest.mock('app/caseDistribution/components/CaseDistributionContent',
      () => () => <mock-details data-testid="testIssues" />
    );
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

    // let inputField = wrapper.find('input[name="test-lever"]');

    // Calls simulate change to set value outside of min/max range
    // waitFor(() => inputField.simulate('change', eventForError));

    // wrapper.update();

    // expect(document.querySelector('.active-lever > .lever-left')).toHaveTextContent(lever.title);
    // expect(document.querySelector('.active-lever > .lever-left')).toHaveTextContent(lever.description);
    // expect(document.querySelector('.active-lever > .lever-right')).toHaveTextContent(lever.value);
  });

});

