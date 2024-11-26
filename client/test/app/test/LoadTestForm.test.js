import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import '@testing-library/jest-dom';
import { MemoryRouter as Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import rootReducer from 'app/queue/reducers';

import LoadTestForm from '../../../app/test/loadTest/LoadTestForm';

describe('LoadTestForm', () => {
  const defaultProps = {
    form_values: {
      all_csum_roles: ['Admin Intake', 'Build HearSched'],
      all_organizations: ['AOD', 'Alexandra Jackson', 'BVA Intake'],
      feature_toggles_available: [
        {
          name: 'acd_cases_tied_to_judges_no_longer_with_board',
          default_status: true
        },
        {
          name: 'acd_disable_legacy_lock_ready_appeals',
          default_status: false
        }
      ],
      functions_available: ['System Admin']
    },
    currentState: {
      scenarios: [],
      user: {
        station_id: '',
        regional_office: '',
        roles: [],
        functions: {},
        organizations: [],
        feature_toggles: {}
      }
    },
    updateState: jest.fn(),
    showAlert: false,
    setShowAlert: jest.fn()
  };

  const store = createStore(rootReducer, applyMiddleware(thunk));

  const setup = (props) =>
    render(
      <Provider store={store}>
        <Router>
          <LoadTestForm {...props} />
        </Router>
      </Provider>
    );

  it('renders the LoadTestForm component', async () => {
    const form = setup(defaultProps);

    expect(form).toMatchSnapshot();
    expect(await screen.findByText('User Configuration')).toBeInTheDocument();
    expect(await screen.findByText('Scenario Groups')).toBeInTheDocument();
    expect(await screen.findByText('Submit')).toBeInTheDocument();
  });

  it('shows errors when missing required selection', async () => {
    setup(defaultProps);
    userEvent.click(screen.getByRole('button', { type: 'Submit' }));

    expect(await screen.findByText('Station ID Required')).toBeInTheDocument();
    expect(await screen.findByText('Regional Office Required')).toBeInTheDocument();
    expect(await screen.findByText('Select at least 1 Target Scenario')).toBeInTheDocument();
  });

  it('submits when required have been selected', async () => {
    defaultProps.currentState.user = {
      station_id: '101',
      regional_office: 'VACO',
      roles: [],
      functions: {},
      organizations: [],
      feature_toggles: {}
    };
    defaultProps.currentState.scenarios = [
      { hearingsShow: {
        targetType: 'LegacyHearing',
        targetId: ''
      } }
    ];
    setup(defaultProps);
    userEvent.click(screen.getByRole('button', { type: 'Submit' }));
    expect(await defaultProps.setShowAlert).toHaveBeenCalledTimes(1);
  });
});

