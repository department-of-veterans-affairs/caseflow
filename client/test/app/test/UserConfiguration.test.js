import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter as Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';
import userEvent from '@testing-library/user-event';

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
      form_values: { functions_available: {} },
      stationId: 'Station ID',
      regionalOffice: 'Regional Office'
    };

    renderUserConfiguration(mockProps);
    expect(await screen.findByText(/Station ID/)).toBeInTheDocument();
  });

  it('renders the Regional Office dropdown when Station ID dropdown is selected', async () => {
    const mockProps = {
      form_values: { functions_available: {} },
      stationId: 'Station ID',
      regionalOffice: 'Regional Office'
    };

    renderUserConfiguration(mockProps);

    const dropdown = screen.getByRole('dropdown', { name: 'Station ID' });

    userEvent.click(dropdown);

    expect(await screen.findAllByText(/Regional Office/)).toBeInTheDocument();
  });
});
