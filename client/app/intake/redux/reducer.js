import { ACTIONS } from '../constants';
import { update } from '../../util/ReducerUtil';

const initialState = {
  veteran: {
    name: null,
    fileNumber: null
  }
};

export default (state = initialState, action) => {
  switch (action.type) {
  case ACTIONS.SET_VETERAN:
    return update(state, {
      veteran: {
        name: {
          $set: action.payload.name
        },
        fileNumber: {
          $set: action.payload.fileNumber
        }
      }
    });
  default:
    return state;
  }
};
