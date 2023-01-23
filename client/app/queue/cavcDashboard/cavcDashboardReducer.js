import { update } from '../../util/ReducerUtil';
import { ACTIONS } from './cavcDashboardConstants';

export const initialState = {
  decision_reasons: {},
  selection_basis: {}
};

export const cavcDashboardReducer = (state = initialState, action) => {
  switch (action.type) {
  case ACTIONS.FETCH_CAVC_DECISION_REASONS:
    return update(state, {
      decision_reasons: {
        $set: action.payload.decision_reasons
      }
    });
  case ACTIONS.FETCH_CAVC_SELECTION_BASIS:
    return update(state, {
      selection_basis: {
        $set: action.payload.selection_basis
      }
    });
  default:
    return state;
  }
};

export default cavcDashboardReducer;
