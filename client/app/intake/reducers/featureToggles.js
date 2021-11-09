import { update } from '../../util/ReducerUtil';

const updateFromServerFeatures = (state, featureToggles) => {
  return update(state, {
    useAmaActivationDate: {
      $set: Boolean(featureToggles.useAmaActivationDate)
    },
    vhaPreDocketAppeals: {
      $set: Boolean(featureToggles.vhaPreDocketAppeals)
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
    veteransReadiness: {
      $set: Boolean(featureToggles.veteransReadiness)
    },
    removeSameOffice: {
      $set: Boolean(featureToggles.removeSameOffice)
    },
  });
};

export const mapDataToFeatureToggle = (data = { featureToggles: {} }) =>
  updateFromServerFeatures(
    {
      useAmaActivationDate: false,
      vhaPreDocketAppeals: false,
      correctClaimReviews: false,
      filedByVaGovHlr: false,
      veteransReadiness: false,
      removeSameOffice: false
    },
    data.featureToggles
  );

export const featureToggleReducer = (state = mapDataToFeatureToggle()) => {
  return state;
};
