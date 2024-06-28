// Import your actual component and dependencies
import React from 'react';
import { render, waitFor } from '@testing-library/react';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware, combineReducers } from 'redux';
import reviewPackageReducer from '../../../../app/queue/correspondence/correspondenceReducer/reviewPackageReducer';
import AutoAssignAlertBanner from '../../../../app/queue/correspondence/component/AutoAssignAlertBanner';
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
      batchId: 123,
      bannerAlert: {}
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

describe('AutoAssignAlertBanner', () => {
  beforeEach(() => {
    jest.resetAllMocks();
    jest.useFakeTimers();
  });
  afterEach(() => {
    jest.clearAllMocks();
    jest.clearAllTimers();
  });

  it('displays success banner after successful auto assignment', async () => {
    const mockResponse = { body: { number_assigned: 5, status: 'completed' } };

    ApiUtil.get.mockResolvedValue(mockResponse);

    const { getByText } = renderWithProviders(
      <AutoAssignAlertBanner />,
      { initialState: initialReviewPackageState }
    );

    await waitFor(() => {
      expect(getByText('You have successfully assigned 5 correspondences')).toBeInTheDocument();
    });

  });

  it('displays error banner after failed auto assignment', async () => {
    const mockResponse = { body: {
      error_message: {
        message: COPY.BAAA_NO_UNASSIGNED_CORRESPONDENCE
      },
      status: 'error'
    } };

    ApiUtil.get.mockResolvedValue(mockResponse);

    const { getByText } = renderWithProviders(
      <AutoAssignAlertBanner />,
      { initialState: initialReviewPackageState }
    );

    await waitFor(() => {
      expect(getByText(COPY.BAAA_UNSUCCESSFUL_TITLE)).toBeInTheDocument();
    });

  });

  it('polls every minute until status is completed', async () => {
    const mockCompletedResponse = { body: { status: 'completed' } };
    const mockPendingResponse = { body: { status: 'pending' } };

    ApiUtil.get.
      mockResolvedValueOnce(mockPendingResponse).
      mockResolvedValueOnce(mockCompletedResponse);

    const { store } = renderWithProviders(
      <AutoAssignAlertBanner />,
      { initialState: initialReviewPackageState }
    );

    await waitFor(() => {
      expect(ApiUtil.get).toHaveBeenCalledTimes(1);
      expect(store.getState().reviewPackage.autoAssign.bannerAlert.type).toBe('pending');
    });

    jest.advanceTimersByTime(60001);

    await waitFor(() => {
      expect(ApiUtil.get).toHaveBeenCalledTimes(2);
      expect(store.getState().reviewPackage.autoAssign.bannerAlert.type).toBe('success');
    });

    jest.advanceTimersByTime(60001);

    await waitFor(() => {
      expect(ApiUtil.get).toHaveBeenCalledTimes(2);
      expect(store.getState().reviewPackage.autoAssign.bannerAlert.type).toBe('success');
    });
  });
});
