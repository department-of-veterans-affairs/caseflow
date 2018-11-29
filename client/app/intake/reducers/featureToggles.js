import { update } from '../../util/ReducerUtil';

const updateFromServerFeatures = (state, featureToggles) => {
  return update(state, {
    intakeAma: {
      $set: Boolean(featureToggles.intakeAma)
    },
    newAddIssuesPage: {
      $set: Boolean(featureToggles.newAddIssuesPage)
    },
    useAmaActivationDate: {
      $set: Boolean(featureToggles.useAmaActivationDate)
    }
  });
};

export const mapDataToFeatureToggle = (data = { featureToggles: {} }) => (
  updateFromServerFeatures({
    intakeAma: false,
    newAddIssuesPage: false,
    useAmaActivationDate: false
  }, data.featureToggles)
);

export const featureToggleReducer = (state = mapDataToFeatureToggle()) => {
  return state;
};
