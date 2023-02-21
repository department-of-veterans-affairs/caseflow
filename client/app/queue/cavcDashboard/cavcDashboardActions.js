import ApiUtil from '../../util/ApiUtil';
import { ACTIONS } from './cavcDashboardConstants';

export const fetchCavcDecisionReasons = () => (dispatch) => {
  ApiUtil.get('/cavc_dashboard/cavc_decision_reasons').then((response) => dispatch({
    type: ACTIONS.FETCH_CAVC_DECISION_REASONS,
    payload: { decision_reasons: response.body }
  }));
};

export const fetchCavcSelectionBases = () => (dispatch) => {
  ApiUtil.get('/cavc_dashboard/cavc_selection_bases').then((response) => dispatch({
    type: ACTIONS.FETCH_CAVC_SELECTION_BASES,
    payload: { selection_bases: response.body }
  }));
};

export const fetchInitialDashboardData = (appealId) => (dispatch) => {
  ApiUtil.
    get(`/cavc_dashboard/${appealId}`, { headers: { accept: 'application/json' } }).
    then((response) => dispatch({
      type: ACTIONS.FETCH_INITIAL_DASHBOARD_DATA,
      payload: {
        cavc_dashboards: response.body.cavc_dashboards
      }
    }));
};

export const updateDashboardIssues = (dashboardIndex, issue) => (dispatch) => {
  dispatch({
    type: ACTIONS.UPDATE_DASHBOARD_ISSUES,
    payload: { dashboardIndex, issue }
  });
};

export const removeDashboardIssue = (dashboardIndex, issue) => (dispatch) => {
  dispatch({
    type: ACTIONS.REMOVE_DASHBOARD_ISSUE,
    payload: { dashboardIndex, issue }
  });
};
