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

