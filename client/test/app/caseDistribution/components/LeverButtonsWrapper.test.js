import React from 'react';
import { render, screen } from '@testing-library/react';
import LeverButtonsWrapper from 'app/caseDistribution/components/LeverButtonsWrapper';
import { Provider } from 'react-redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import leversReducer from 'app/caseDistribution/reducers/levers/leversReducer';
import { ACTIONS } from 'app/caseDistribution/reducers/levers/leversActionTypes';
import * as leverData from 'test/data/adminCaseDistributionLevers';

describe('LeverButtonsWrapper', () => {

  afterEach(() => {
    jest.clearAllMocks();
  });

  test('renders save and cancel buttons', () => {

    const getStore = () => createStore(
      rootReducer,
      applyMiddleware(thunk));

    const store = getStore();

    render(
      <Provider store={store}>
        <LeverButtonsWrapper />
      </Provider>
    );

    const saveButton = screen.getByRole('button', { name: /Save/i });

    expect(saveButton).toBeInTheDocument();

    const cancelButton = screen.getByRole('button', { name: /Cancel/i });

    expect(cancelButton).toBeInTheDocument();
  });
});
