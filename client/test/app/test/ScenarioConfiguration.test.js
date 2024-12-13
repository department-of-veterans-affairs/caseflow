import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import '@testing-library/jest-dom';
import { MemoryRouter as Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import rootReducer from 'app/queue/reducers';

import ScenarioConfiguration from '../../../app/test/loadTest/ScenarioConfiguration';

describe('ScenarioConfiguration', () => {
  const defaultProps = {
    scenario: 'scenarioTest',
    targetType: ['Target1', 'Target2', 'Target3'],
    currentState: {
      scenarios: [],
      user: {
        station_id: '',
        regional_office: '',
        roles: [],
        functions: {},
        organizations: [],
        feature_toggles: {
          listed_granted_substitution_before_dismissal: true
        }
      }
    },
    updateState: jest.fn(),
    errors: {}
  };

  const store = createStore(rootReducer, applyMiddleware(thunk));

  const setup = (props) =>
    render(
      <Provider store={store}>
        <Router>
          <ScenarioConfiguration {...props} />
        </Router>
      </Provider>
    );

  it('renders the ScenarioConfiguration component', async () => {
    const scenarioComponent = setup(defaultProps);

    expect(scenarioComponent).toMatchSnapshot();
    expect(await scenarioComponent.findByText(/scenarioTest/)).toBeInTheDocument();
  });

  it('displays dropdown when checkbox is clicked', async () => {
    setup(defaultProps);
    userEvent.click(screen.getByRole('checkbox', { name: 'scenarioTest' }));

    expect(screen.getAllByText(/Target Type/).length).toEqual(2);
  });
});

