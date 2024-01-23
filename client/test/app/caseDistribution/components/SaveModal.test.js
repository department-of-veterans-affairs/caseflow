import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react';
import { Provider } from 'react-redux';
import { createStore } from 'redux';
import '@testing-library/jest-dom/extend-expect';
import { LeverSaveButton } from '../../../../app/caseDistribution/components/LeverSaveButton';
import leversReducer from '../../../../app/caseDistribution/reducers/levers/leversReducer';

const useDispatchMock = jest.fn();
const useSelectorMock = jest.fn();

jest.mock('react-redux', () => ({
  ...jest.requireActual('react-redux'),
  useDispatch: useDispatchMock,
  useSelector: useSelectorMock,
}));

describe('LeverSaveButton', () => {
  let store;
  let dispatchMock;

  beforeEach(() => {
    const mockInitialState = {
      levers: [],
      historyList: [],
    };

    store = createStore(leversReducer, mockInitialState);

    dispatchMock = jest.fn();
    useDispatchMock.mockReturnValue(dispatchMock);
    useSelectorMock.mockReturnValue(mockInitialState);
  });

  it('dispatches the saveLevers action when clicked', async () => {
    // useSelectorMock.mockReturnValue(initialState);

    const { getByText } = render(
      <Provider store={store}>
        <LeverSaveButton />
      </Provider>
    );

    const saveButton = getByText('Save');

    expect(saveButton).toBeInTheDocument();

    fireEvent.click(saveButton);

    await waitFor(async () => {
      expect(dispatchMock).toHaveBeenCalledWith(expect.any(Function));
    });
  });

  // it('triggers modal when Save button is clicked', async () => {
  //   const mockState = {
  //     ...initialState,
  //   };

  //   useSelectorMock.mockReturnValue(mockState);

  //   const { getByText } = render(
  //     <Provider store={store}>
  //       <LeverSaveButton />
  //     </Provider>
  //   );

  //   const saveButton = getByText('Save');

  //   fireEvent.click(saveButton);

  //   await waitFor(() => {
  //     expect(getByText('Modal Content')).toBeInTheDocument();
  //   });
  // });

});
