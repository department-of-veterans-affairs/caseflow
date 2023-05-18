import ApiUtil from '../../util/ApiUtil';
import { ACTIONS } from './cavcDashboardConstants';

const meta = (label) => ({
  analytics: {
    category: 'CAVC Dashboard Actions',
    action: null,
    label,
  }
});

export const fetchCavcDecisionReasons = () => (dispatch) => {
  ApiUtil.get('/cavc_dashboard/cavc_decision_reasons').then((response) => dispatch({
    type: ACTIONS.FETCH_CAVC_DECISION_REASONS,
    payload: { decision_reasons: response.body },
    meta: meta()
  }));
};

export const fetchCavcSelectionBases = () => (dispatch) => {
  ApiUtil.get('/cavc_dashboard/cavc_selection_bases').then((response) => dispatch({
    type: ACTIONS.FETCH_CAVC_SELECTION_BASES,
    payload: { selection_bases: response.body },
    meta: meta()
  }));
};

export const fetchInitialDashboardData = (appealId) => (dispatch) => {
  ApiUtil.
    get(`/cavc_dashboard/${appealId}`, { headers: { accept: 'application/json' } }).
    then((response) => dispatch({
      type: ACTIONS.FETCH_INITIAL_DASHBOARD_DATA,
      payload: {
        cavc_dashboards: response.body.cavc_dashboards
      },
      meta: meta(`Appeal UUID ${appealId}`)
    }));
};

export const updateDashboardData = (dashboardIndex, updatedData) => (dispatch) => {
  ApiUtil.
    patch('/cavc_dashboard/update', { data: {
      dashboardIndex, updatedData }
    }).
    then(dispatch({
      type: ACTIONS.UPDATE_DASHBOARD_DATA,
      payload: { dashboardIndex, updatedData },
      meta: meta(`Dashboard Index ${dashboardIndex}`)
    }));
};

export const resetDashboardData = () => (dispatch) => {
  dispatch({
    type: ACTIONS.RESET_DASHBOARD_DATA,
    meta: meta()
  });
};

export const setCheckedDecisionReasons = (checkedReasons, issueId) => ({
  type: ACTIONS.SET_CHECKED_DECISION_REASONS,
  payload: {
    checkedReasons,
    issueId,
  },
  meta: meta(`Issue Id ${issueId}`)
});

export const setSelectionBasisForReasonCheckbox = (uniqueId, selectionBasesIndex, option) => ({
  type: ACTIONS.SET_BASIS_FOR_REASON_CHECKBOX,
  payload: {
    issueId: uniqueId,
    selectionBasesIndex,
    checkboxId: option.checkboxId,
    parentCheckboxId: option.parentCheckboxId,
    label: option.label,
    value: option.value
  },
  meta: meta(`Issue Id ${uniqueId} ${option}`)
});

export const setInitialCheckedDecisionReasons = (uniqueId) => ({
  type: ACTIONS.SET_INITIAL_CHECKED_DECISION_REASONS,
  payload: {
    uniqueId
  },
  meta: meta(`Issue Id ${uniqueId}`)
});

export const removeCheckedDecisionReason = (issueId) => ({
  type: ACTIONS.REMOVE_CHECKED_DECISION_REASON,
  payload: { issueId },
  meta: meta(`Issue Id ${issueId}`)
});

export const updateDashboardIssues = (dashboardIndex, issue, dashboardDisposition) => (dispatch) => {
  dispatch({
    type: ACTIONS.UPDATE_DASHBOARD_ISSUES,
    payload: { dashboardIndex, issue, dashboardDisposition },
    meta: meta(`Dashboard Index ${dashboardIndex}, Issue ${issue?.id}, Disposition ${dashboardDisposition}`)
  });
};

export const setDispositionValue = (dashboardIndex, dispositionIssueId, dispositionOption) => (dispatch) => {
  dispatch({
    type: ACTIONS.SET_DISPOSITION_VALUE,
    payload: { dashboardIndex, dispositionIssueId, dispositionOption },
    meta: meta(
      `Dashboard Index ${dashboardIndex}, Disposition Id ${dispositionIssueId}, Disposition Option ${dispositionOption}`
    )
  });
};

export const removeDashboardIssue = (dashboardIndex, issue) => (dispatch) => {
  dispatch({
    type: ACTIONS.REMOVE_DASHBOARD_ISSUE,
    payload: { dashboardIndex, issue },
    meta: meta(`Dashboard Index ${dashboardIndex}, Issue ${issue.id}`)
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

    selectedBoxes.forEach((box) => {
      if (box.selection_bases.length > 0) {
        checkedBoxesByIssueId.push({
          issue_id: issueId,
          issue_type: box.issueType,
          decision_reason_id: box.id,
          basis_for_selection_category: box.basis_for_selection_category,
          selection_bases: box.selection_bases
        });
      } else {
        checkedBoxesByIssueId.push({ issue_id: issueId, issue_type: box.issueType, decision_reason_id: box.id });
      }
    });
  }

  return ApiUtil.post('/cavc_dashboard/save',
    { data: {
      cavc_dashboards: usableCavcDashboards,
      checked_boxes: checkedBoxesByIssueId
    } }).
    then((response) => {
      return response.body.successful;
    }).
    catch((error) => {
      const responseError = error.message;

      dispatch({
        type: ACTIONS.SAVE_DASHBOARD_DATA_FAILURE,
        payload: { responseError },
        meta: meta()
      });
    });
};
