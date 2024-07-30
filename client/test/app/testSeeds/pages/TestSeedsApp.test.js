import React from 'react';
import TestSeedsApp from 'app/testSeeds/pages/TestSeedsApp';
import { render, screen } from '@testing-library/react';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/testSeeds/reducers/root';
import thunk from 'redux-thunk';

describe('render Test Seeds Application', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk)
  );

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('renders Test Seeds App', () => {

    const store = getStore();

    render(
      <Provider store={store}>
        <TestSeedsApp />
      </Provider>
    );

    expect(screen.getByText('Custom Seeds')).toBeInTheDocument();
  });
});

