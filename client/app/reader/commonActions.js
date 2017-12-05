import {
  HIDE_ERROR_MESSAGE,
  SHOW_ERROR_MESSAGE,
  UPDATE_FILTERED_DOC_IDS
} from './constants';

// errors

export const hideErrorMessage = (messageType) => ({
  type: HIDE_ERROR_MESSAGE,
  payload: {
    messageType
  }
});

export const showErrorMessage = (messageType) => ({
  type: SHOW_ERROR_MESSAGE,
  payload: {
    messageType
  }
});

// Apply filters

export const updateFilteredIds = () => (dispatch, getState) => {
  const { annotationLayer } = getState();

  dispatch({
    type: UPDATE_FILTERED_DOC_IDS,
    payload: {
      annotationLayer
    }
  });
};
