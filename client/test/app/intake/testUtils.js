import PropTypes from 'prop-types';
import React from 'react';
import { render } from '@testing-library/react';
import { Provider } from 'react-redux';
import { Router } from 'react-router';
import { createStore } from 'redux';

import { reducer, generateInitialState } from 'app/intake/index';

const IntakeProviders = ({ children, storeValues, history }) => {
  const store = createStore(reducer, { ...storeValues });

  return (
    <Provider store={store}>
      <Router history={history}>{children}</Router>
    </Provider>
  );
};

IntakeProviders.propTypes = {
  children: PropTypes.any,
  history: PropTypes.object,
  storeValues: PropTypes.object
};

export const renderIntakePage = (
  children,
  storeValues = generateInitialState(),
  history
) => {
  return {
    ...render(
      <IntakeProviders storeValues={storeValues} history={history} >
        {children}
      </IntakeProviders>
    ),
    history
  };
};
