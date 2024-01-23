import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import { LeverSaveButton } from '../../../../app/caseDistribution/components/LeverSaveButton';
// import SaveModal from '../../../../app/caseDistribution/components/SaveModal';

jest.mock('../../../../app/caseDistribution/components/SaveModal', () => jest.fn(() => null));

describe('LeverSaveButton', () => {
  const mockReducer = (state = {}, action) => {


    return state;
  };

  let store;
  let dispatchMock;

  beforeEach(() => {
    dispatchMock = jest.fn();
    store = createStore(mockReducer, applyMiddleware(thunk));
    jest.spyOn(store, 'dispatch').mockImplementation(dispatchMock);
  });

  it('renders the component correctly', () => {
    const { getByText } = render(
      <Provider store={store}>
        <LeverSaveButton />
      </Provider>
    );

    expect(getByText('Save')).toBeInTheDocument();
  });

  it('opens the modal when Save button is clicked', async () => {
    const { getByText } = render(
      <Provider store={store}>
        <LeverSaveButton />
      </Provider>
    );

    fireEvent.click(getByText('Save'));

    await waitFor(() => {
      expect(dispatchMock).toHaveBeenCalled();
      expect(dispatchMock).toHaveBeenCalledWith(expect.any(Function));
    });
  });

});
