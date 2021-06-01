import { update } from '../../util/ReducerUtil';

const updateFromServerFeatures = (state, featureToggles) => {
  return update(state, {
    useAmaActivationDate: {
      $set: Boolean(featureToggles.useAmaActivationDate)
    },
    correctClaimReviews: {
      $set: Boolean(featureToggles.correctClaimReviews)
    },
    unidentifiedIssueDecisionDate: {
      $set: Boolean(featureToggles.unidentifiedIssueDecisionDate)
    },
    covidTimelinessExemption: {
      $set: Boolean(featureToggles.covidTimelinessExemption)
    },
    verifyUnidentifiedIssue: {
      $set: Boolean(featureToggles.verifyUnidentifiedIssue)
    },
    restrictAppealIntakes: {
      $set: Boolean(featureToggles.restrictAppealIntakes)
    },
    attorneyFees: {
      $set: Boolean(featureToggles.attorneyFees)
    },
    nonVeteranClaimants: {
      $set: Boolean(featureToggles.nonVeteranClaimants)
    },
    establishFiduciaryEps: {
      $set: Boolean(featureToggles.establishFiduciaryEps)
    },
    deceasedAppellants: {
      $set: Boolean(featureToggles.deceasedAppellants)
    },
    editEpClaimLabels: {
      $set: Boolean(featureToggles.editEpClaimLabels)
    },
  });
};

export const mapDataToFeatureToggle = (data = { featureToggles: {} }) =>
  updateFromServerFeatures(
    {
      useAmaActivationDate: false,
      correctClaimReviews: false,
      unidentifiedIssueDecisionDate: false,
      verifyUnidentifiedIssue: false,
      restrictAppealIntakes: false,
      establishFiduciaryEps: false,
      editEpClaimLabels: false,
      deceasedAppellants: false
    },
    data.featureToggles
  );

export const featureToggleReducer = (state = mapDataToFeatureToggle()) => {
  return state;
};
