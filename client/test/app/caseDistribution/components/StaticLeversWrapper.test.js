import React from 'react';
import { render } from '@testing-library/react';
import StaticLeversWrapper from 'app/caseDistribution/components/StaticLeversWrapper';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { loadLevers } from 'app/caseDistribution/reducers/levers/leversActions';
import { levers } from '../../../data/adminCaseDistributionLevers';

describe('Static Lever', () => {

  afterEach(() => {
    jest.clearAllMocks();
  });

  let staticLevers = levers.filter((lever) => (lever.lever_group === 'static' && lever.data_type === 'number'));
  let testLevers = {
    static: staticLevers,
  };

  it('renders the Static Lever', () => {

    const getStore = () => createStore(
      rootReducer,
      applyMiddleware(thunk));

    const store = getStore();

    store.dispatch(loadLevers(testLevers));

    render(
      <Provider store={store}>
        <StaticLeversWrapper />
      </Provider>
    );

    for (const lever of staticLevers) {
      expect(document.getElementById(`${lever.item}-value`)).toHaveTextContent(lever.value);
      expect(document.getElementById(`${lever.item}-description`)).toHaveTextContent(lever.description);
      expect(document.getElementById(`${lever.item}-unit`)).toHaveTextContent(lever.unit);
    }
  });
});
