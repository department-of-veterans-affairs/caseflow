import { fromPairs, map } from 'lodash';
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
        $set: fromPairs(map(action.payload.correspondences, (cor) => [
          cor.id,
          {
            ...cor,
            checked: false
          }
        ]))
      }
    });

  default:
    return state;
  }
};

export default intakeCorrespondenceReducer;
