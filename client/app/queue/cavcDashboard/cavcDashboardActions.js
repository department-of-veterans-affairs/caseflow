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

export const setCheckedDecisionReasons = (checkedReasons, issueId) => ({
  type: ACTIONS.SET_CHECKED_DECISION_REASONS,
  payload: {
    checkedReasons,
    issueId,
  }
});

export const removeCheckedDecisionReason = (issueId) => ({
  type: ACTIONS.REMOVE_CHECKED_DECISION_REASON,
  payload: { issueId }
});

export const updateDashboardIssues = (dashboardIndex, issue, dashboardDisposition) => (dispatch) => {
  dispatch({
    type: ACTIONS.UPDATE_DASHBOARD_ISSUES,
    payload: { dashboardIndex, issue, dashboardDisposition }
  });
};

export const removeDashboardIssue = (dashboardIndex, issueIndex) => (dispatch) => {
  dispatch({
    type: ACTIONS.REMOVE_DASHBOARD_ISSUE,
    payload: { dashboardIndex, issueIndex }
  });
};

export const updateDashboardData = (dashboardIndex, updatedData) => (dispatch) => {
  dispatch({
    type: ACTIONS.UPDATE_DASHBOARD_DATA,
    payload: { dashboardIndex, updatedData }
  });
};

export const saveDashboardData = (allCavcDashboards, checkedBoxes) => (dispatch) => {
  const usableCavcDashboards = allCavcDashboards.map((dashboard) => {
    const formattedDash = {
      id: dashboard.id,
      cavc_dashboard_dispositions: dashboard.cavc_dashboard_dispositions,
      cavc_dashboard_issues: dashboard.cavc_dashboard_issues,
    };

    return formattedDash;
  });

  const checkedBoxesByIssueId = [];

  for (const [issueId, value] of Object.entries(checkedBoxes)) {
    const parentBoxes = Object.values(value);
    const childBoxes = parentBoxes.map((box) => box.children).flat();
    const allBoxes = parentBoxes.concat(childBoxes);
    const selectedBoxes = allBoxes.filter((box) => box.checked);
    const idsAndTypes = selectedBoxes.map((box) => [box.issueType, box.id]);

    idsAndTypes.map((idsAndType) => checkedBoxesByIssueId.push([issueId, ...idsAndType]));
    //idsAndTypes.map((idsAndType) => checkedBoxesByIssueId.push({ issueId, idsAndType }));
  }

  ApiUtil.post('/cavc_dashboard/save',
    { data: {
      cavc_dashboards: usableCavcDashboards,
      checked_boxes: checkedBoxesByIssueId
    } }).
    then(() => {
      return true;
    }).
    catch((error) => {
      const responseError = error.message;

      dispatch({
        type: ACTIONS.SAVE_DASHBOARD_DATA_FAILURE,
        payload: { responseError }
      });
    });
};
