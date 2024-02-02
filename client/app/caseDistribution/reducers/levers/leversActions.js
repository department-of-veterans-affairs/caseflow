import { ACTIONS } from './leversActionTypes';
import ApiUtil from '../../../util/ApiUtil';

export const setUserIsAcdAdmin = (isUserAcdAdmin) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SET_USER_IS_ACD_ADMIN,
      payload: {
        isUserAcdAdmin
      }
    });
  };

export const loadLevers = (levers) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.LOAD_LEVERS,
      payload: {
        levers
      }
    });
  };

export const loadHistory = (historyList) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.LOAD_HISTORY,
      payload: {
        historyList
      }
    });
  };

export const resetLevers = () => async (dispatch) => {
  const resp = await ApiUtil.get('/case_distribution_levers/get_levers');
  const { levers } = resp.body;

  dispatch({
    type: ACTIONS.LOAD_LEVERS,
    payload: {
      levers,
    },
  });
};

export const updateRadioLever = (leverGroup, leverItem, value, optionValue = null) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.UPDATE_RADIO_LEVER,
      payload: {
        leverGroup,
        leverItem,
        value,
        optionValue
      }
    });
  };

export const updateLeverIsToggleActive = (leverGroup, leverItem, toggleValue) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.UPDATE_LEVER_IS_TOGGLE_ACTIVE,
      payload: {
        leverGroup,
        leverItem,
        toggleValue
      }
    });
  };

export const updateLeverValue = (leverGroup, leverItem, value) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.UPDATE_LEVER_VALUE,
      payload: {
        leverGroup,
        leverItem,
        value
      }
    });
  };

export const saveLevers = (levers) =>
  (dispatch) => {
    const changedValues = levers.
      map((lever) => ({
        id: lever.id,
        value: lever.value,
        is_toggle_active: lever.is_toggle_active
      }));

    const postData = {
      current_levers: changedValues
    };

    return ApiUtil.post('/case_distribution_levers/update_levers', { data: postData }).
      then((resp) => resp.body).
      then((resp) => {
        dispatch({
          type: ACTIONS.LOAD_LEVERS,
          payload: {
            levers: resp.levers,
          }
        });
        dispatch({
          type: ACTIONS.SAVE_LEVERS,
          payload: {
            errors: resp.errors,
          }
        });
        dispatch({
          type: ACTIONS.LOAD_HISTORY,
          payload: {
            historyList: resp.lever_history
          }
        });
      });
  };

export const hideSuccessBanner = () =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.HIDE_BANNER
    });
  };

export const addLeverErrors = (errors) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.ADD_LEVER_VALIDATION_ERRORS,
      payload: {
        errors
      }
    });
  };

export const removeLeverErrors = (leverItem) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.REMOVE_LEVER_VALIDATION_ERRORS,
      payload: {
        leverItem
      }
    });
  };

export const resetAllLeverErrors = () =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.RESET_ALL_VALIDATION_ERRORS
    });
  };
