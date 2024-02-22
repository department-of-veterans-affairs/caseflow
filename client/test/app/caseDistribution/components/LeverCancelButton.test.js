import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react';
import { Provider, useDispatch, useSelector } from 'react-redux';
import { createStore } from 'redux';
import '@testing-library/jest-dom/extend-expect';
import { LeverCancelButton } from '../../../../app/caseDistribution/components/LeverCancelButton';
import COPY from '../../../../COPY';
import leversReducer from '../../../../app/caseDistribution/reducers/levers/leversReducer';

jest.mock('react-redux', () => ({
  ...jest.requireActual('react-redux'),
  useDispatch: jest.fn(),
  useSelector: jest.fn(),
}));

describe('LeverCancelButton', () => {
  let store;
  let dispatchMock;

  beforeEach(() => {
    const mockInitialState = {
      levers: [],
      historyList: [],
    };

    store = createStore(leversReducer, mockInitialState);

    dispatchMock = jest.fn();
    useDispatch.mockReturnValue(dispatchMock);

    useSelector.mockReturnValue(mockInitialState);
  });

  it('renders the component correctly', () => {
    const { getByText } = render(
      <Provider store={store}>
        <LeverCancelButton />
      </Provider>
    );

    expect(getByText(COPY.CASE_DISTRIBUTION_LEVER_CANCEL_BUTTON)).toBeInTheDocument();
  });

  it('dispatches the resetLevers action when clicked', async () => {
    const { getByText } = render(
      <Provider store={store}>
        <LeverCancelButton />
      </Provider>
    );
    const cancelButton = getByText(COPY.CASE_DISTRIBUTION_LEVER_CANCEL_BUTTON);

    expect(cancelButton).toBeInTheDocument();

    fireEvent.click(cancelButton);

    await waitFor(() => {
      expect(dispatchMock).toHaveBeenCalledTimes(2);
      expect(dispatchMock).toHaveBeenCalledWith(expect.any(Function));
      expect(dispatchMock).toHaveBeenCalledWith(expect.any(Function));
    });
  });
});

