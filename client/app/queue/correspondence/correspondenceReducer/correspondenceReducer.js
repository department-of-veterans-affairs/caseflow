import { update } from '../../../util/ReducerUtil';
import { ACTIONS } from './correspondenceConstants';

export const initialState = {
  correspondences: []
};


export const intakeCorrespondenceReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.LOAD_CORRESPONDENCES:
    return update(state, {
      correspondences: {
        $set: action.payload.correspondences
      }
    });

  default:
    return state;
  }
};

export default intakeCorrespondenceReducer;
