import React from 'react';
import { render, screen } from '@testing-library/react';
import { mount } from 'enzyme';
import RadioField from 'app/components/RadioField';
import ExclusionTable from 'app/caseDistribution/components/ExclusionTable';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { mockDocketLevers } from '../../../data/adminCaseDistributionLevers';
import { loadLevers, setUserIsAcdAdmin } from 'app/caseDistribution/reducers/levers/leversActions';

describe('Exclusion Table', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

  let leversWithTestingDocketLevers = { docket_levers: mockDocketLevers };
  let leverPriority = mockDocketLevers[0];
  let leverNonPriority = mockDocketLevers[4];

  it('Exclusion Table Renders all 8 Levers as Admin', () => {
    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingDocketLevers));
    store.dispatch(setUserIsAcdAdmin(true));

    const wrapper = mount((<Provider store={store}>
      <ExclusionTable />
    </Provider>
    ));

    expect(wrapper.find(RadioField)).toHaveLength(4);
  });

  it('Exclusion Table Renders all 8 Levers for Member View', () => {
    const store = getStore();
    const expectedPriorityValues = leverPriority.value ? 'ON' : 'OFF';
    const expectedNonpriorityValues = leverNonPriority.value ? 'ON' : 'OFF';

    store.dispatch(loadLevers(leversWithTestingDocketLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <ExclusionTable />
      </Provider>
    );

    const leverStatusPriority = screen.queryAllByText(expectedPriorityValues);
    const leverStatusNonPriority = screen.queryAllByText(expectedNonpriorityValues);

    expect(leverStatusPriority).toHaveLength(4);
    expect(leverStatusNonPriority).toHaveLength(4);
  });

});
