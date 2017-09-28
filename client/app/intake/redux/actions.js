import { ACTIONS } from '../constants';

export const setVeteran = (name, fileNumber) => ({
  type: ACTIONS.SET_VETERAN,
  payload: {
    name,
    fileNumber
  }
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
      setVeteran({
        name: 'Joe Snuffy',
        fileNumber: '222222222'
      });
      resolve();
    }, 1000);
  })
};
