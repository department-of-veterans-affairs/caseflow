import { update } from '../../util/ReducerUtil';

const updateFromServerFeatures = (state, featureToggles) => {
  return update(state, {
    useAmaActivationDate: {
      $set: Boolean(featureToggles.useAmaActivationDate)
    },
    correctClaimReviews: {
      $set: Boolean(featureToggles.correctClaimReviews)
    },
    covidTimelinessExemption: {
      $set: Boolean(featureToggles.covidTimelinessExemption)
    },
  });
};

export const mapDataToFeatureToggle = (data = { featureToggles: {} }) =>
  updateFromServerFeatures(
    {
      useAmaActivationDate: false,
      correctClaimReviews: false,
    },
    data.featureToggles
  );

export const featureToggleReducer = (state = mapDataToFeatureToggle()) => {
  return state;
};
