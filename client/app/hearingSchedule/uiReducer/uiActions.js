import { ACTIONS } from './uiConstants';

export const setUserCssId = (cssId) => ({
  type: ACTIONS.SET_USER_CSS_ID,
  payload: {
    cssId
  }
});
