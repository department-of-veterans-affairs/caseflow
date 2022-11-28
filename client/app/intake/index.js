import React from 'react';
import PropTypes from 'prop-types';
import { combineReducers } from 'redux';
import IntakeFrame from './IntakeFrame';
import { intakeReducer, mapDataToInitialIntake } from './reducers/intake';
import {
  rampElectionReducer,
  mapDataToInitialRampElection,
} from './reducers/rampElection';
import {
  rampRefilingReducer,
  mapDataToInitialRampRefiling,
} from './reducers/rampRefiling';
import {
  supplementalClaimReducer,
  mapDataToInitialSupplementalClaim,
} from './reducers/supplementalClaim';
import {
  higherLevelReviewReducer,
  mapDataToInitialHigherLevelReview,
} from './reducers/higherLevelReview';
import { appealReducer, mapDataToInitialAppeal } from './reducers/appeal';
import {
  featureToggleReducer,
  mapDataToFeatureToggle,
} from './reducers/featureToggles';
import addClaimantReducer from './reducers/addClaimantSlice';
import ReduxBase from '../components/ReduxBase';
import { BrowserRouter } from 'react-router-dom';

export const reducer = combineReducers({
  intake: intakeReducer,
  rampElection: rampElectionReducer,
  rampRefiling: rampRefilingReducer,
  supplementalClaim: supplementalClaimReducer,
  higherLevelReview: higherLevelReviewReducer,
  appeal: appealReducer,
  featureToggles: featureToggleReducer,
  addClaimant: addClaimantReducer,
});

export const generateInitialState = (props) => ({
  intake: mapDataToInitialIntake(props),
  rampElection: mapDataToInitialRampElection(props),
  rampRefiling: mapDataToInitialRampRefiling(props),
  supplementalClaim: mapDataToInitialSupplementalClaim(props),
  higherLevelReview: mapDataToInitialHigherLevelReview(props),
  appeal: mapDataToInitialAppeal(props),
  featureToggles: mapDataToFeatureToggle(props),
});

class Intake extends React.PureComponent {
  componentDidMount() {
    if (window.Raven) {
      window.Raven.caseflowAppName = 'intake';
    }
  }

  render() {
    const initialState = generateInitialState(this.props);
    const Router = this.props.router || BrowserRouter;

    return (
      <ReduxBase
        initialState={initialState}
        reducer={reducer}
        analyticsMiddlewareArgs={['intake']}
      >
        <Router basename="/intake" {...this.props.routerTestProps}>
          <IntakeFrame {...this.props} />
        </Router>
      </ReduxBase>
    );
  }
}
Intake.propTypes = {
  router: PropTypes.object,
  routerTestProps: PropTypes.object,
};

export default Intake;
