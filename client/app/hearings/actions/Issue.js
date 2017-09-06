import * as Constants from '../constants/constants';

export const onDescriptionChange = (description) => ({
  type: Constants.SET_DESCRIPTION,
  payload: {
    description
  }
});

export const onToggleReopen = (reopen) => ({
  type: Constants.SET_REPNAME,
  payload: {
    reopen
  }
});
