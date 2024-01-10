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

export const updateRadioLever = (leverGroup, leverItem, value, optionValue = null, toggleValue = false) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.UPDATE_RADIO_LEVER,
      payload: {
        leverGroup,
        leverItem,
        value,
        optionValue,
        toggleValue
      }
    });
  };

export const updateCombinationLever = (leverGroup, leverItem, value, optionValue = null, toggleValue = false) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.UPDATE_COMBINATION_LEVER,
      payload: {
        leverGroup,
        leverItem,
        value,
        optionValue,
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

