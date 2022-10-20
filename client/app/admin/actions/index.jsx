import { ACTIONS } from '../constants';

export const setFeatureToggles = (featureToggles) => ({
  type: ACTIONS.SET_FEATURE_TOGGLES,
  payload: { featureToggles }
});
