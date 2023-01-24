import ApiUtil from "../../util/ApiUtil";
import { ACTIONS } from "./cavcDashboardConstants";

export const fetchCavcDecisionReasons = () => (dispatch) => {
  ApiUtil.get('/cavc_dashboard/cavc_decision_reasons').then((response) => dispatch({
    type: ACTIONS.FETCH_CAVC_DECISION_REASONS,
    payload: { decision_reasons: response.body }
  }));
};

export const fetchCavcSelectionBases = () => (dispatch) => {
  ApiUtil.get('/cavc_dashboard/cavc_selection_bases').then((response) => dispatch({
    type: ACTIONS.FETCH_CAVC_SELECTION_BASES,
    payload: { selection_basis: response.body }
  }));
};
