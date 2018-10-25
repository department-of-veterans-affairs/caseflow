import { update } from '../../util/ReducerUtil';

const updateFromServerFeatures = (state, featureToggles) => {
  return update(state, {
    intakeAma: {
      $set: Boolean(featureToggles.intakeAma)
    },
    newAddIssuesPage: {
      $set: Boolean(featureToggles.newAddIssuesPage)
    }
  });
};


export const mapDataToFeatureToggle = (data = { featureToggles: {} }) => (
  updateFromServerFeatures({
    intakeAma: false,
    newAddIssuesPage: false
  }, data.featureToggles)
);

export const featureToggleReducer = (state = mapDataToFeatureToggle(), action) => {
  return state;
}