import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter as Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';

import LoadTest from '../../../app/test/loadTest/LoadTest';

const createStoreWithReducer = (initialState) => {
  const reducer = (state = initialState) => state;

  return createStore(reducer, compose(applyMiddleware(thunk)));
};

const renderLoadTest = (props) => {
  const store = createStoreWithReducer({ components: {} });

  return render(
    <Provider store={store}>
      <Router>
        <LoadTest {...props} />
      </Router>
    </Provider>
  );
};

describe('LoadTest', () => {
  it('renders the Test Target Configuration page', async () => {
    const mockProps = {
      form_values: {},
      page: 'Test App',
      featuresList: ['Toggle1', 'Toggle2', 'Toggle3'],
    };

    renderLoadTest(mockProps);
    expect(await screen.findByText(/Test Target Configuration/)).toBeInTheDocument();
  });
});
