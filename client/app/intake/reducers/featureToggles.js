import { update } from '../../util/ReducerUtil';

const updateFromServerFeatures = (state, featureToggles) => {
  return update(state, {
    intakeAma: {
      $set: Boolean(featureToggles.intakeAma)
    },
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
    intakeAma: false,
    useAmaActivationDate: false,
    withdrawDecisionReviews: false
  }, data.featureToggles)
);

export const featureToggleReducer = (state = mapDataToFeatureToggle()) => {
  return state;
};
