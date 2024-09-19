import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter as Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';

import FunctionConfiguration from '../../../app/test/loadTest/FeatureToggleConfiguration';

const createStoreWithReducer = (initialState) => {
  const reducer = (state = initialState) => state;

  return createStore(reducer, compose(applyMiddleware(thunk)));
};

const renderFunctionConfiguration = (props) => {
  const store = createStoreWithReducer({ components: {} });

  return render(
    <Provider store={store}>
      <Router>
        <FunctionConfiguration {...props} />
      </Router>
    </Provider>
  );
};

describe('FeatureToggleConfiguration', () => {
  it('renders the FeatureToggleConfiguration component', async () => {
    const mockProps = {
      form_values: {},
      page: 'Test App',
    };

    renderFunctionConfiguration(mockProps);
    expect(await screen.findByText(/Functions/)).toBeInTheDocument();
  });
});
