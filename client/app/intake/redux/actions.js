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
