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
    mstIdentification: {
      $set: Boolean(featureToggles.mstIdentification)
    },
    pactIdentification: {
      $set: Boolean(featureToggles.pactIdentification)
    },
    justificationReason: {
      $set: Boolean(featureToggles.justificationReason)
    },
    legacyMstPactIdentification: {
      $set: Boolean(featureToggles.legacyMstPactIdentification)
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
      mstIdentification: false,
      pactIdentification: false,
      legacyMstPactIdentification: false,
      justificationReason: false,
      updatedAppealForm: false,
      hlrScUnrecognizedClaimants: false,
      vhaClaimReviewEstablishment: false
    },
    data.featureToggles
  );

export const featureToggleReducer = (state = mapDataToFeatureToggle()) => {
  return state;
};
