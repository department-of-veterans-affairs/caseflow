import React from 'react';
import { mount } from 'enzyme';
import ExcludeDocketLever from 'app/caseDistribution/components/ExcludeDocketLever';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { mockDocketLevers } from '../../../data/adminCaseDistributionLevers';
import { loadLevers, setUserIsAcdAdmin } from 'app/caseDistribution/reducers/levers/leversActions';

describe('Exclusion Lever', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

  let leversWithTestingAffinityDaysLevers = { docket_levers: mockDocketLevers };
  let lever = mockDocketLevers[0];

  it('Exclusion Lever Renders', () => {
    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingAffinityDaysLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    const wrapper = mount((<Provider store={store}>
      <ExcludeDocketLever
        lever={lever}
      />
    </Provider>
    ));

    let input = (wrapper.find('input').at(1));

    // All 8 levers are rendered
    expect(wrapper).toBeDefined();
    expect(input.instance().value).toBe('false');
  });

  it('Exclusion Lever Change Value', () => {
    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingAffinityDaysLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    const wrapper = mount((<Provider store={store}>
      <ExcludeDocketLever
        lever={lever}
      />
    </Provider>
    ));

    let input = (wrapper.find('input').at(0));

    input.simulate('change', { lever, event: { value: true } });

    expect(input.instance().value).toBeTruthy();
  });

});
