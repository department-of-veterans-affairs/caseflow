import {
  HIDE_ERROR_MESSAGE,
  SHOW_ERROR_MESSAGE
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
