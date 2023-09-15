import { update } from '../../util/ReducerUtil';

const updateFromServerFeatures = (state, featureToggles) => {
  return update(state, {
    correctClaimReviews: {
      $set: Boolean(featureToggles.correctClaimReviews)
    },
    covidTimelinessExemption: {
      $set: false
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
    }
  });
};

export const mapDataToFeatureToggle = (data = { featureToggles: {} }) =>
  updateFromServerFeatures(
    {
      correctClaimReviews: false,
      filedByVaGovHlr: false,
      updatedIntakeForms: false,
      eduPreDocketAppeals: false,
      updatedAppealForm: false
    },
    data.featureToggles
  );

export const featureToggleReducer = (state = mapDataToFeatureToggle()) => {
  return state;
};
