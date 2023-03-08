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

export const updateDashboardData = (dashboardIndex, updatedData) => (dispatch) => {
  ApiUtil.
    patch('/cavc_dashboard/update', { data: {
      dashboardIndex, updatedData }
    }).
    then(dispatch({
      type: ACTIONS.UPDATE_DASHBOARD_DATA,
      payload: { dashboardIndex, updatedData }
    }));
};

export const resetDashboardData = () => (dispatch) => {
  dispatch({
    type: ACTIONS.RESET_DASHBOARD_DATA
  });
};

export const setCheckedDecisionReasons = (checkedReasons, issueId) => ({
  type: ACTIONS.SET_CHECKED_DECISION_REASONS,
  payload: {
    checkedReasons,
    issueId,
  }
});

export const setSelectionBasisForReasonCheckbox = (uniqueId, option) => ({
  type: ACTIONS.SET_BASIS_FOR_REASON_CHECKBOX,
  payload: {
    issueId: uniqueId,
    checkboxId: option.checkboxId,
    parentCheckboxId: option.parentCheckboxId,
    label: option.label,
    value: option.value
  }
});

export const updateOtherFieldTextValue = (uniqueId, value, reasons) => ({
  type: ACTIONS.UPDATE_OTHER_FIELD_TEXT_VALUE,
  payload: {
    issueId: uniqueId,
    checkboxId: reasons.checkboxId,
    parentCheckboxId: reasons.parentCheckboxId,
    value
  }
});

export const setInitialCheckedDecisionReasons = (uniqueId) => ({
  type: ACTIONS.SET_INITIAL_CHECKED_DECISION_REASONS,
  payload: {
    uniqueId
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

export const setDispositionValue = (dashboardIndex, dispositionId, dispositionOption) => (dispatch) => {
  dispatch({
    type: ACTIONS.SET_DISPOSITION_VALUE,
    payload: { dashboardIndex, dispositionId, dispositionOption }
  });
};

export const removeDashboardIssue = (dashboardIndex, issueIndex, dispositionIndex) => (dispatch) => {
  dispatch({
    type: ACTIONS.REMOVE_DASHBOARD_ISSUE,
    payload: { dashboardIndex, issueIndex, dispositionIndex }
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
    const idsAndTypes = selectedBoxes.map((box) => {
      if (box.basis_for_selection.value) {
        return [
          box.issueType,
          box.id,
          box.basis_for_selection_category,
          box.basis_for_selection
        ];
      }

      return [box.issueType, box.id];
    });

    idsAndTypes.map((idsAndType) => checkedBoxesByIssueId.push([issueId, ...idsAndType]));
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
        payload: { responseError }
      });
    });
};
