import { ACTIONS } from './leversActionTypes';

export const loadLevers = (loadedLevers) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.LOAD_LEVERS,
      payload: {
        loadedLevers
      }
    });
  };

export const updateLeverValue = (leverValue) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.UPDATE_LEVER_VALUE,
      payload: {
        leverValue
      }
    });
  };

export const formatLeverHistory = (leverHistory) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.FORMAT_LEVER_HISTORY,
      payload: {
        leverHistory
      }
    });
  };

export const saveLever = (lever) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SAVE_LEVERS,
      payload: {
        lever
      }
    });
  };

export const revertLevers = (lever) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.REVERT_LEVERS,
      payload: {
        lever
      }
    });
  };

export const successBanner = (banner) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SHOW_SUCCESS_BANNER,
      payload: {
        banner
      }
    });
  };
