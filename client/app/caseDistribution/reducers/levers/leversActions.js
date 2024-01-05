import { ACTIONS } from './leversActionTypes';

export const initialLoad = (levers) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.INITIAL_LOAD,
      payload: {
        levers
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

// work in progress
export const formatLeverHistory = (leverHistory) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.FORMAT_LEVER_HISTORY,
      payload: {
        leverHistory
      }
    });
  };

