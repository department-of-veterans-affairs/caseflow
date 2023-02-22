import { update } from '../../util/ReducerUtil';
import { ACTIONS } from './cavcDashboardConstants';

export const initialState = {
  decision_reasons: {},
  selection_bases: {},
  cavc_dashboards: [],
  dashboard_issues: []
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
  case ACTIONS.UPDATE_DASHBOARD_ISSUES:
    return update(state, {
      cavc_dashboards: {
        [action.payload.dashboardIndex]: {
          cavc_dashboard_issues: {
            $push: [action.payload.issue]
          }
        }
      }
    });
  case ACTIONS.REMOVE_DASHBOARD_ISSUE:
    return update(state, {
      cavc_dashboards: {
        [action.payload.dashboardIndex]: {
          cavc_dashboard_issues: {
            $splice: [[action.payload.issueIndex, 1]]
          }
        }
      }
    });
  default:
    return state;
  }
};

export default cavcDashboardReducer;
