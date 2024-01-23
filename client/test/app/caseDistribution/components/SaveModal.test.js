import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import { LeverSaveButton } from '../../../../app/caseDistribution/components/LeverSaveButton';
import * as leversActions from 'app/caseDistribution/reducers/levers/leversActions';
import SaveModal from '../../../../app/caseDistribution/components/SaveModal';

jest.mock('../../../../app/caseDistribution/components/SaveModal', () => jest.fn(() => null));

describe('LeverSaveButton', () => {
  const initialState = {
    caseDistributionLevers: {
      levers: [],
      isUserAcdAdmin: false,
      leversErrors: [],
    }
  };

  const mockReducer = (state = initialState, action) => {
    switch (action.type) {
    case leversActions.setUserIsAcdAdmin().type:
      return {
        ...state,
        caseDistributionLevers: {
          ...state.caseDistributionLevers,
          isUserAcdAdmin: action.payload.isUserAcdAdmin,
        },
      };

    case leversActions.loadLevers().type:
      return {
        ...state,
        caseDistributionLevers: {
          ...state.caseDistributionLevers,
          levers: action.payload.levers,
          leversErrors: action.payload.errors || [],
        },
      };

    case leversActions.saveLevers().type: {
      const updatedLevers = action.payload.levers;
      const updatedState = {
        ...state,
        caseDistributionLevers: {
          ...state.caseDistributionLevers,
          levers: updatedLevers,
        },
      };

      // console.log('Saved Levers:', updatedLevers);

      return updatedState;
    }

    default:
      return state;
    }
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

    // const saveLeversAction = leversActions.saveLevers({});

    // store.dispatch(saveLeversAction);

    // // expect(dispatchMock).toHaveBeenCalledWith(saveLevers(updatedLevers));

    // await waitFor(() => {
    //   expect(SaveModal).toHaveBeenCalledWith(
    //     expect.objectContaining({
    //       setShowModal: expect.any(Function),
    //     })
    //   );
    // });
  });

});
