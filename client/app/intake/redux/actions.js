import { ACTIONS } from '../constants';

export const setVeteran = (name, fileNumber) => ({
  type: ACTIONS.SET_VETERAN,
  payload: {
    name,
    fileNumber
  }
});
