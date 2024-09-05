import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event'
import '@testing-library/jest-dom';
import { MemoryRouter as Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';

import ScenarioConfiguration from '../../../app/test/loadTest/ScenarioConfiguration';

const createStoreWithReducer = (initialState) => {
  const reducer = (state = initialState) => state;

  return createStore(reducer, compose(applyMiddleware(thunk)));
};

const renderScenarioConfiguration = (props) => {
  const store = createStoreWithReducer({ components: {} });

  return render(
    <Provider store={store}>
      <Router>
        <ScenarioConfiguration {...props} />
      </Router>
    </Provider>
  );
};

describe('ScenarioConfiguration', () => {
  it('renders the ScenarioConfiguration component', async () => {
    const mockProps = {
      scenario: 'scenarioTest',
      testTarget: ['Target1', 'Target2', 'Target3'],
    };

    renderScenarioConfiguration(mockProps);
    expect(await screen.findByText(/scenarioTest/)).toBeInTheDocument();
  });

  it('displays dropdown when checkbox is clicked', async () => {
    const mockProps = {
      scenario: 'scenarioTest',
      targetType: ['Target1', 'Target2', 'Target3'],
    };

    renderScenarioConfiguration(mockProps);

    const checkbox = screen.getByRole('checkbox', { name: 'scenarioTest' });

    userEvent.click(checkbox);

    // The Target Type dropdown and Target Type ID input field should be displayed
    expect(await screen.findAllByText(/Target Type/).length == 2);
  });
});

