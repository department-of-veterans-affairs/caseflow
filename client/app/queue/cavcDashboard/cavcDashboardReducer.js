import { update } from '../../util/ReducerUtil';
import { ACTIONS } from './cavcDashboardConstants';

export const initialState = {
  decision_reasons: {}
};

export const cavcDashboardReducer = (state = initialState, action) => {
  switch (action.type) {
  case ACTIONS.FETCH_CAVC_DECISION_REASONS:
    return update(state, {
      decision_reasons: {
        $set: action.payload.decision_reasons
      }
    });
  default:
    return state;
  }
};

export default cavcDashboardReducer;
