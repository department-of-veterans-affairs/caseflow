import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import '@testing-library/jest-dom';
import { MemoryRouter as Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import rootReducer from 'app/queue/reducers';

import RoleConfiguration from '../../../app/test/loadTest/RoleConfiguration';

describe('RoleConfiguration', () => {
  const defaultProps = {
    role: 'Build HearSched',
    currentState: {
      scenarios: [],
      user: {
        station_id: '',
        regional_office: '',
        roles: ['Edit HearSched'],
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
          <RoleConfiguration {...props} />
        </Router>
      </Provider>
    );

  it('renders the RoleConfiguration component', async () => {
    const roleComponent = setup(defaultProps);

    expect(roleComponent).toMatchSnapshot();
    expect(await screen.findByText('Build HearSched')).toBeInTheDocument();
  });

  it('updates state when checkbox is clicked', async () => {
    setup(defaultProps);
    await userEvent.click(screen.getByRole('checkbox', { name: 'Build HearSched' }));

    expect(defaultProps.currentState.user.roles).toEqual(['Edit HearSched', 'Build HearSched']);
  });
});

