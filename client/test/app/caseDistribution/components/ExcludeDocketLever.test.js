import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
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
  let lever = mockDocketLevers[0];

  let selectedLever = {
    displayText: lever.title,
    item: lever.item,
    value: lever.value,
    disabled: lever.is_disabled_in_ui,
    options: lever.options,
    leverGroup: lever.lever_group,
  };

  let leversWithTestingDocketLevers = { docket_levers: mockDocketLevers };

  it('Exclusion Lever Renders', () => {
    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingDocketLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <ExcludeDocketLever
          lever={selectedLever}
        />
    </Provider>
    );

    const input = screen.getByRole('radio', {name: 'Off'});
    // // All 8 levers are rendered
    expect(input).toBeInTheDocument();
    expect(input.value).toBe('false');
  });

  it('Exclusion Lever Change Value', () => {
    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingDocketLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
    <Provider store={store}>
      <ExcludeDocketLever
        lever={selectedLever}
      />
    </Provider>
  );

    const input = screen.getByRole('radio', {name: 'On'});

    fireEvent.change(input, { target: { value: 'true' } });
    expect(input.value).toBe('true');
  });
});
