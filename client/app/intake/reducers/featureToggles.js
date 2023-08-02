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
    filedByVaGovHlr: {
      $set: Boolean(featureToggles.filedByVaGovHlr)
    },
    updatedIntakeForms: {
      $set: Boolean(featureToggles.updatedIntakeForms)
    },
    eduPreDocketAppeals: {
      $set: Boolean(featureToggles.eduPreDocketAppeals)
    },
    updatedAppealForm: {
      $set: Boolean(featureToggles.updatedAppealForm)
    },
    hlrScUnrecognizedClaimants: {
      $set: Boolean(featureToggles.hlrScUnrecognizedClaimants)
    },
    vhaClaimReviewEstablishment: {
      $set: Boolean(featureToggles.vhaClaimReviewEstablishment)
    }
  });
};

export const mapDataToFeatureToggle = (data = { featureToggles: {} }) =>
  updateFromServerFeatures(
    {
      useAmaActivationDate: false,
      correctClaimReviews: false,
      filedByVaGovHlr: false,
      updatedIntakeForms: false,
      eduPreDocketAppeals: false,
      updatedAppealForm: false,
      hlrScUnrecognizedClaimants: false,
      vhaClaimReviewEstablishment: false
    },
    data.featureToggles
  );

export const featureToggleReducer = (state = mapDataToFeatureToggle()) => {
  return state;
};
