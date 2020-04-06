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

export const reducer = combineReducers({
  intake: intakeReducer,
  rampElection: rampElectionReducer,
  rampRefiling: rampRefilingReducer,
  supplementalClaim: supplementalClaimReducer,
  higherLevelReview: higherLevelReviewReducer,
  appeal: appealReducer,
  featureToggles: featureToggleReducer
});

export const generateInitialState = (props) => ({
  intake: mapDataToInitialIntake(props),
  rampElection: mapDataToInitialRampElection(props),
  rampRefiling: mapDataToInitialRampRefiling(props),
  supplementalClaim: mapDataToInitialSupplementalClaim(props),
  higherLevelReview: mapDataToInitialHigherLevelReview(props),
  appeal: mapDataToInitialAppeal(props),
  featureToggles: mapDataToFeatureToggle(props)
});

class Intake extends React.PureComponent {
  componentDidMount() {
    if (window.Raven) {
      window.Raven.caseflowAppName = 'intake';
    }
  }

  render() {
    const initialState = generateInitialState(this.props);

    return (
      <ReduxBase initialState={initialState} reducer={reducer} analyticsMiddlewareArgs={['intake']}>
        <IntakeFrame {...this.props} />
      </ReduxBase>
    );
  }
}

export default Intake;
