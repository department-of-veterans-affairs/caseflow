import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter as Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';
import selectEvent from 'react-select-event';

import UserConfiguration from '../../../app/test/loadTest/UserConfiguration';

const createStoreWithReducer = (initialState) => {
  const reducer = (state = initialState) => state;

  return createStore(reducer, compose(applyMiddleware(thunk)));
};

const renderUserConfiguration = (props) => {
  const store = createStoreWithReducer({ components: {} });

  return render(
    <Provider store={store}>
      <Router>
        <UserConfiguration {...props} />
      </Router>
    </Provider>
  );
};

describe('UserConfiguration', () => {
  it('renders the Station ID dropdown', async () => {
    const mockProps = {
      filteredStations: '101',
      officeAvailable: 'VACO',
      form_values: { functions_available: '' },
      featuresList: ['Toggle1', 'Toggle2', 'Toggle3']
    };

    renderUserConfiguration(mockProps);
    expect(await screen.findByText(/Station ID/)).toBeInTheDocument();
  });

  it('renders the Regional Office dropdown when Station ID dropdown is selected', async () => {
    const mockProps = {
      filteredStations: [{ value: '101', label: '101' }],
      officeAvailable: 'VACO',
      form_values: { functions_available: '' },
      featuresList: ['Toggle1', 'Toggle2', 'Toggle3']
    };

    renderUserConfiguration(mockProps);

    const stationDropdown = screen.getByRole('combobox', { name: 'Station id dropdown' });

    fireEvent.change(stationDropdown, { target: { value: '101' } });

    await selectEvent.select(
      stationDropdown,
      ['101']
    );

    const officeDropdown = screen.getByRole('combobox', { name: 'Regional office dropdown' });

    expect(await officeDropdown).toBeInTheDocument();
  });
});
