import { update } from '../../util/ReducerUtil';

const updateFromServerFeatures = (state, featureToggles) => {
  return update(state, {
    useAmaActivationDate: {
      $set: Boolean(featureToggles.useAmaActivationDate)
    },
    vhaPreDocketWorkflow: {
      $set: Boolean(featureToggles.vhaPreDocketWorkflow)
    },
    correctClaimReviews: {
      $set: Boolean(featureToggles.correctClaimReviews)
    },
    covidTimelinessExemption: {
      $set: Boolean(featureToggles.covidTimelinessExemption)
    },
    filedByVaGovHlr: {
      $set: Boolean(featureToggles.filedByVaGovHlr)
    },
  });
};

export const mapDataToFeatureToggle = (data = { featureToggles: {} }) =>
  updateFromServerFeatures(
    {
      useAmaActivationDate: false,
      vhaPreDocketWorkflow: false,
      correctClaimReviews: false,
      filedByVaGovHlr: false
    },
    data.featureToggles
  );

export const featureToggleReducer = (state = mapDataToFeatureToggle()) => {
  return state;
};
