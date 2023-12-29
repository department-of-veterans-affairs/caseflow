import { update } from '../../../util/ReducerUtil';
import { ACTIONS } from './caseflowDistributionAdminConstants';

export const initialState = {
  caseflowDistribution: []
};

export const caseflowDistributionAdminReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.TEST_REDUX:
    return update(state, {
      caseflowDistribution: {
        $set: [...action.payload.data]
      }
    });

  default:
    return state;
  }
};

export default caseflowDistributionAdminReducer;
