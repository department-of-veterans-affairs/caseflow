import React from 'react';
import { Provider } from 'react-redux';
import { MemoryRouter } from 'react-router';
import { createStore } from 'redux';

import { reducer, generateInitialState } from 'app/intake/index';

export const IntakeProviders = ({ children }) => {
  const store = createStore(reducer, { ...generateInitialState() });

  return (
    <Provider store={store}>
      <MemoryRouter>{children}</MemoryRouter>
    </Provider>
  );
};
