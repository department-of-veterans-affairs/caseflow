import React from 'react';
import { combineReducers } from 'redux';
import IntakeFrame from './IntakeFrame';
import { intakeReducer, mapDataToInitialIntake } from './reducers/intake';
import { rampElectionReducer, mapDataToInitialRampElection } from './reducers/rampElection';
import { rampRefilingReducer, mapDataToInitialRampRefiling } from './reducers/rampRefiling';
import { supplementalClaimReducer, mapDataToInitialSupplementalClaim } from './reducers/supplementalClaim';
import { higherLevelReviewReducer, mapDataToInitialHigherLevelReview } from './reducers/higherLevelReview';
import { appealReducer, mapDataToInitialAppeal } from './reducers/appeal';
import { featureToggleReducer, mapDataToFeatureToggle } from './reducers/featureToggles';
import ReduxBase from '../components/ReduxBase';

const reducer = combineReducers({
  intake: intakeReducer,
  rampElection: rampElectionReducer,
  rampRefiling: rampRefilingReducer,
  supplementalClaim: supplementalClaimReducer,
  higherLevelReview: higherLevelReviewReducer,
  appeal: appealReducer,
  featureToggles: featureToggleReducer
});

class Intake extends React.PureComponent {
  componentDidMount() {
    if (window.Raven) {
      window.Raven.caseflowAppName = 'intake';
    }
  }

  render() {
    const initialState = {
      intake: mapDataToInitialIntake(this.props),
      rampElection: mapDataToInitialRampElection(this.props),
      rampRefiling: mapDataToInitialRampRefiling(this.props),
      supplementalClaim: mapDataToInitialSupplementalClaim(this.props),
      higherLevelReview: mapDataToInitialHigherLevelReview(this.props),
      appeal: mapDataToInitialAppeal(this.props),
      featureToggles: mapDataToFeatureToggle(this.props)
    };

    return <ReduxBase initialState={initialState} reducer={reducer} analyticsMiddlewareArgs={['intake']}>
      <IntakeFrame {...this.props} />
    </ReduxBase>;
  }
}

export default Intake;
