import { ACTIONS } from '../constants';

export const startNewIntake = () => ({
  type: ACTIONS.START_NEW_INTAKE
});

export const setFileNumberSearch = (fileNumber) => ({
  type: ACTIONS.SET_FILE_NUMBER_SEARCH,
  payload: {
    fileNumber
  }
});

export const doFileNumberSearch = () => (dispatch) => {
  return new Promise((resolve) => {
    dispatch({
      type: ACTIONS.FILE_NUMBER_SEARCH_START
    });
    setTimeout(() => {
      dispatch({
        type: ACTIONS.FILE_NUMBER_SEARCH_SUCCEED,
        payload: {
          name: 'Joe Snuffy',
          fileNumber: '222222222'
        }
      });
      resolve();
    }, 1000);
  });
};
