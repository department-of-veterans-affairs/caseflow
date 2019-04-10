import { update } from '../../util/ReducerUtil';

const updateFromServerFeatures = (state, featureToggles) => {
  return update(state, {
    useAmaActivationDate: {
      $set: Boolean(featureToggles.useAmaActivationDate)
    },
    withdrawDecisionReviews: {
      $set: Boolean(featureToggles.withdrawDecisionReviews)
    }
  });
};

export const mapDataToFeatureToggle = (data = { featureToggles: {} }) => (
  updateFromServerFeatures({
    useAmaActivationDate: false,
    withdrawDecisionReviews: false
  }, data.featureToggles)
);

export const featureToggleReducer = (state = mapDataToFeatureToggle()) => {
  return state;
};
