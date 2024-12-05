import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter as Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import selectEvent from 'react-select-event';
import rootReducer from 'app/queue/reducers';

import UserConfiguration from '../../../app/test/loadTest/UserConfiguration';

describe('UserConfiguration', () => {
  const defaultProps = {
    filteredStations: [{ value: '101', label: '101' }],
    officeAvailable: 'VACO',
    form_values: {
      all_csum_roles: ['Admin Intake', 'Build HearSched'],
      functions_available: ['System Admin'],
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
      ] },
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
    errors: {}
  };

  const store = createStore(rootReducer, applyMiddleware(thunk));

  const setup = (props) =>
    render(
      <Provider store={store}>
        <Router>
          <UserConfiguration {...props} />
        </Router>
      </Provider>
    );

  it('renders the Station ID dropdown', async () => {
    expect(setup(defaultProps)).toMatchSnapshot();
    expect(await screen.findByText(/Station ID/)).toBeInTheDocument();
  });

  it('renders the Regional Office dropdown when Station ID dropdown is selected', async () => {
    const mockProps = {
      filteredStations: [{ value: '101', label: '101' }],
      officeAvailable: 'VACO',
      form_values: { functions_available: '' },
      featuresList: ['Toggle1', 'Toggle2', 'Toggle3'],
      currentState: {
        scenarios: [],
        user: {
          user: {
            station_id: '',
            regional_office: '',
            roles: [],
            functions: {},
            organizations: [],
            feature_toggles: {}
          }
        }
      },
      updateState: jest.fn()
    };

    renderUserConfiguration(mockProps);

    const stationDropdown = screen.getByRole('combobox', { name: 'Station id dropdown' });

    fireEvent.change(stationDropdown, { target: { value: '101' } });

    await selectEvent.select(
      stationDropdown,
      ['101']
    );

    const officeDropdown = screen.getByRole('combobox', { name: 'Regional office dropdown' });

    expect(officeDropdown).toBeInTheDocument();
  });

  it('renders Organizations, Functions, Roles, & Feature Toggles', async () => {
    setup(defaultProps);

    expect(await screen.findByText('Organizations')).toBeInTheDocument();
    expect(await screen.findByText('Alexandra Jackson')).toBeInTheDocument();
    expect(await screen.findByText('Functions')).toBeInTheDocument();
    expect(await screen.findByText('System Admin')).toBeInTheDocument();
    expect(await screen.findByText('Roles')).toBeInTheDocument();
    expect(await screen.findByText('Build HearSched')).toBeInTheDocument();
    expect(await screen.findByText('Feature Toggles')).toBeInTheDocument();
    expect(await screen.findByText('acd_cases_tied_to_judges_no_longer_with_board')).toBeInTheDocument();
  });
});
