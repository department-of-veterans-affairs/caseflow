import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react';
import { Provider, useDispatch, useSelector } from 'react-redux';
import { createStore } from 'redux';
import '@testing-library/jest-dom/extend-expect';
import { LeverCancelButton } from '../../../../app/caseDistribution/components/LeverCancelButton';
import COPY from '../../../../COPY';
import leversReducer from '../../../../app/caseDistribution/reducers/levers/leversReducer';

// Mock the useDispatch and useSelector hooks
jest.mock('react-redux', () => ({
  ...jest.requireActual('react-redux'),
  useDispatch: jest.fn(),
  useSelector: jest.fn(),
}));

describe('LeverCancelButton', () => {
  let store;
  let dispatchMock;

  beforeEach(() => {
    // Set up a mock Redux store
    const mockInitialState = {
      levers: [],
      historyList: [],
    };

    store = createStore(leversReducer, mockInitialState);

    // Mock the dispatch function
    dispatchMock = jest.fn();
    useDispatch.mockReturnValue(dispatchMock);

    // Mock the useSelector to return the desired state
    useSelector.mockReturnValue(mockInitialState);
  });

  it('renders the component correctly', () => {
    const { getByText } = render(
      <Provider store={store}>
        <LeverCancelButton />
      </Provider>
    );

    // Add assertions based on your component's expected behavior
    expect(getByText(COPY.CASE_DISTRIBUTION_LEVER_CANCEL_BUTTON)).toBeInTheDocument();
    // Add more assertions as needed
  });

  it('dispatches the revertLevers action when clicked', async () => {
    const { getByText } = render(
      <Provider store={store}>
        <LeverCancelButton />
      </Provider>
    );
    const cancelButton = getByText(COPY.CASE_DISTRIBUTION_LEVER_CANCEL_BUTTON);

    // Check if the button is present
    expect(cancelButton).toBeInTheDocument();

    // Simulate a button click
    fireEvent.click(cancelButton);

    await waitFor(() => {

      // Verify that dispatch was called with the expected action
      expect(dispatchMock).toHaveBeenCalledWith(expect.any(Function));});
  });
});

