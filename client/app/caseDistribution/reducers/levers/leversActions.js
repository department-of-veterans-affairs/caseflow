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
export const revertLevers = () =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.REVERT_LEVERS,
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

export const updateCombinationLever = (leverGroup, leverItem, value, toggleValue = false) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.UPDATE_COMBINATION_LEVER,
      payload: {
        leverGroup,
        leverItem,
        value,
        toggleValue
      }
    });
  };

export const updateBooleanLever = (leverGroup, leverItem, value) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.UPDATE_BOOLEAN_LEVER,
      payload: {
        leverGroup,
        leverItem,
        value
      }
    });
  };

export const updateTextLever = (leverGroup, leverItem, value) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.UPDATE_TEXT_LEVER,
      payload: {
        leverGroup,
        leverItem,
        value
      }
    });
  };

export const updateNumberLever = (leverGroup, leverItem, value) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.UPDATE_NUMBER_LEVER,
      payload: {
        leverGroup,
        leverItem,
        value
      }
    });
  };

export const saveLevers = (levers) =>
  (dispatch) => {
    const changedValues = Object.values(levers).flat().
      map((lever) => ({
        id: lever.id,
        value: lever.value
      }));

    const postData = {
      current_levers: changedValues
    };

    return ApiUtil.post('/case_distribution_levers/update_levers', { data: postData }).
      then((resp) => resp.body).
      then((resp) => {
        dispatch({
          type: ACTIONS.SAVE_LEVERS,
          payload: {
            successful: resp.successful,
            errors: resp.errors,
            leverHistory: resp.lever_history
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
