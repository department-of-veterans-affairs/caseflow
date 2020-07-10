import { update } from '../../util/ReducerUtil';

const updateFromServerFeatures = (state, featureToggles) => {
  return update(state, {
    useAmaActivationDate: {
      $set: Boolean(featureToggles.useAmaActivationDate)
    },
    editContentionText: {
      $set: Boolean(featureToggles.editContentionText)
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
    }
  });
};

export const mapDataToFeatureToggle = (data = { featureToggles: {} }) =>
  updateFromServerFeatures(
    {
      useAmaActivationDate: false,
      editContentionText: false,
      correctClaimReviews: false,
      unidentifiedIssueDecisionDate: false,
      verifyUnidentifiedIssue: false,
      restrictAppealIntakes: false
    },
    data.featureToggles
  );

export const featureToggleReducer = (state = mapDataToFeatureToggle()) => {
  return state;
};
