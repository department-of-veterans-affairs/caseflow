import React from 'react';
import { render, screen } from '@testing-library/react';
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
  let lever = mockDocketLevers[0];

  it('Exclusion Table Renders all 8 Levers', () => {
    const store = getStore();
    const expectedMemberString = lever.value ? 'ON' : 'OFF';

    store.dispatch(loadLevers(leversWithTestingDocketLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <ExclusionTable />
      </Provider>
    );

    const leverStatus = screen.queryAllByText(expectedMemberString);

    // All 8 levers are rendered
    expect(leverStatus).toHaveLength(8);
  });

});
