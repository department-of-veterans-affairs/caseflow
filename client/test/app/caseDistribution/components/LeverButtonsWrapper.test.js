import React from 'react';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import LeverButtonsWrapper from 'app/caseDistribution/components/LeverButtonsWrapper';
import { Provider } from 'react-redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import * as leversSelectors from 'app/caseDistribution/reducers/levers/leversSelector';
import { resetLevers } from 'app/caseDistribution/reducers/levers/leversActions';

describe('LeverButtonsWrapper', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('renders save and cancel buttons', () => {
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

  test('Save Button be disabled initially', () => {
    const store = getStore();

    render(
      <Provider store={store}>
        <LeverButtonsWrapper />
      </Provider>
    );

    expect(screen.getByText('Save')).toBeDisabled();
  });

  it('activates Save Button when conditions are met', () => {
    const store = getStore();

    const changedLeversData = [
      { title: 'Alternate Batch Size*',
        backendValue: '50',
        value: '15',
        data_type: 'number' },
    ];

    jest.spyOn(leversSelectors, 'hasChangedLevers').mockReturnValue(changedLeversData);

    render(
      <Provider store={store}>
        <LeverButtonsWrapper />
      </Provider>
    );

    expect(screen.getByText('Save')).not.toBeDisabled();
  });

  test('clicking the Cancel Button resets levers to their initial state', async () => {
    const store = getStore();
    const resetLeversAction = resetLevers();

    render(
      <Provider store={store}>
        <LeverButtonsWrapper />
      </Provider>
    );

    const cancelButton = screen.getByRole('button', { name: /Cancel/i });

    fireEvent.click(cancelButton);

    await waitFor(() => {
      expect(store.dispatch).toHaveBeenCalledWith(expect.any(Function));
      expect(store.dispatch).toHaveBeenCalledWith(resetLeversAction);
    });
  });
});
