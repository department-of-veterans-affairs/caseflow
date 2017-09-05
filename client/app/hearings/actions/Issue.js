import * as Constants from '../constants/constants';

export const onDescriptionChange = (description) => ({
  type: Constants.SET_DESCRIPTION,
  payload: {
    description
  }
});

