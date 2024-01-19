import React from 'react';
import { render, screen } from '@testing-library/react';
import StaticLeversWrapper from 'app/caseDistribution/components/StaticLeversWrapper';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import ACD_LEVERS from '../../../../constants/ACD_LEVERS';
import DISTRIBUTION from '../../../../constants/DISTRIBUTION';
import { loadLevers } from 'app/caseDistribution/reducers/levers/leversActions';

describe('Static Lever', () => {

  afterEach(() => {
    jest.clearAllMocks();
  });

  let staticLevers = [
    {
      item: DISTRIBUTION.minimum_legacy_proportion,
      title: 'Minimum Legacy Proportion',
      description: 'Sets the minimum proportion of legacy appeals that will be distributed.',
      data_type: ACD_LEVERS.data_types.number,
      value: 0.2,
      unit: '%',
      is_toggle_active: false,
      is_disabled_in_ui: true,
      min_value: 0,
      max_value: 1,
      algorithms_used: [ACD_LEVERS.algorithms.proportion],
      lever_group: ACD_LEVERS.lever_groups.static,
      lever_group_order: 1001
    },
  ];

  let levers = {
    static: staticLevers,
  };

  it('renders the Static Lever', () => {

    const getStore = () => createStore(
      rootReducer,
      applyMiddleware(thunk));

    const store = getStore();

    store.dispatch(loadLevers(levers));

    render(
      <Provider store={store}>
        <StaticLeversWrapper />
      </Provider>
    );

    expect(screen.getByText('Sets the minimum proportion of legacy appeals that will be distributed.')).
      toBeInTheDocument();
    expect(screen.getByText('20')).toBeInTheDocument();
  });
});
