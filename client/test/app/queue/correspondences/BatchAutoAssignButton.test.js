// Import your actual component and dependencies
import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware, combineReducers } from 'redux';
import reviewPackageReducer from '../../../../app/queue/correspondence/correspondenceReducer/reviewPackageReducer';
import BatchAutoAssignButton from '../../../../app/queue/correspondence/component/BatchAutoAssignButton';
import thunk from 'redux-thunk';
import COPY from '../../../../COPY';
import ApiUtil from '../../../../app/util/ApiUtil';
jest.mock('../../../../app/util/ApiUtil');

const rootReducer = combineReducers({
  reviewPackage: reviewPackageReducer
});

const initialReviewPackageState = {
  reviewPackage: {
    autoAssign: {
      isButtondisabled: false,
    }
  }
};

const renderWithProviders = (
  component,
  { initialState, store = createStore(rootReducer, initialState, applyMiddleware(thunk)) }) => {

  return {
    ...render(
      <Provider store={store}>
        { component }
      </Provider>
    ),
    store
  };
};

describe('BatchAutoAssignButton', () => {
  it('renders the enabled button', () => {
    const { getByText } = renderWithProviders(
      <BatchAutoAssignButton />,
      { initialState: initialReviewPackageState }
    );

    expect(getByText(COPY.AUTO_ASSIGN_CORRESPONDENCES_BUTTON)).not.toBeDisabled();
  });

  it('calls handleAutoAssign and makes api call to correspondence_controller#auto_assign_correspondences', async () => {
    const { getByText } = renderWithProviders(
      <BatchAutoAssignButton />,
      { initialState: initialReviewPackageState }
    );

    fireEvent.click(getByText(COPY.AUTO_ASSIGN_CORRESPONDENCES_BUTTON));

    await waitFor(() => expect(ApiUtil.get).toHaveBeenCalledWith('/queue/correspondence/auto_assign_correspondences'));
  });
});
