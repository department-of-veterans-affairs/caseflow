import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import '@testing-library/jest-dom';
import { MemoryRouter as Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import rootReducer from 'app/queue/reducers';

import OrganizationsConfiguration from '../../../app/test/loadTest/OrganizationsConfiguration';

describe('OrganizationsConfiguration', () => {
  const defaultProps = {
    org: 'BVA Intake',
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

  afterEach(() => {
    jest.resetAllMocks();
    jest.clearAllMocks();
    jest.restoreAllMocks();
  });

  const store = createStore(rootReducer, applyMiddleware(thunk));

  const setup = (props) =>
    render(
      <Provider store={store}>
        <Router>
          <OrganizationsConfiguration {...props} />
        </Router>
      </Provider>
    );

  it('renders the OrganizationsConfiguration component', async () => {
    const OrgComponent = setup(defaultProps);

    expect(OrgComponent).toMatchSnapshot();
    expect(await screen.findByText('BVA Intake')).toBeInTheDocument();
  });

  it('updates state when checkbox is clicked', async () => {
    setup(defaultProps);
    await userEvent.click(screen.getByRole('checkbox', { name: 'BVA Intake' }));

    expect(defaultProps.currentState.user.organizations).toEqual([{ url: 'BVA Intake', admin: false }]);
    expect(await screen.findByText('Admin')).toBeInTheDocument();

    await userEvent.click(screen.getByRole('checkbox', { name: 'BVA Intake admin' }));
    expect(defaultProps.currentState.user.organizations).toEqual([{ url: 'BVA Intake', admin: true }]);
  });
});
