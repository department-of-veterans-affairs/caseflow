import { update } from '../../util/ReducerUtil';
import { ACTIONS } from './cavcDashboardConstants';

export const initialState = {
  decision_reasons: {},
  selection_bases: {},
  cavc_dashboards: []
};

export const cavcDashboardReducer = (state = initialState, action) => {
  switch (action.type) {
  case ACTIONS.FETCH_CAVC_DECISION_REASONS:
    return update(state, {
      decision_reasons: {
        $set: action.payload.decision_reasons
      }
    });
  case ACTIONS.FETCH_CAVC_SELECTION_BASES:
    return update(state, {
      selection_bases: {
        $set: action.payload.selection_bases
      }
    });
  case ACTIONS.FETCH_INITIAL_DASHBOARD_DATA:
    return update(state, {
      cavc_dashboards: {
        $set: action.payload.cavc_dashboards
      }
    });
  case ACTIONS.UPDATE_DASHBOARD_DATA:
    return update(state, {
      cavc_dashboards: {
        [action.payload.dashboardIndex]: {
          board_decision_date: {
            $set: [action.payload.updatedData.boardDecisionDateUpdate]
          },
          board_docket_number: {
            $set: [action.payload.updatedData.boardDocketNumberUpdate]
          },
          cavc_decision_date: {
            $set: [action.payload.updatedData.cavcDecisionDateUpdate]
          },
          cavc_docket_number: {
            $set: [action.payload.updatedData.cavcDocketNumberUpdate]
          },
          joint_motion_for_remand: {
            $set: [action.payload.updatedData.jointMotionForRemandUpdate]
          }
        }
      }
    });
  default:
    return state;
  }
};

export default cavcDashboardReducer;
