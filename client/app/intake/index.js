import React from 'react';
import { combineReducers } from 'redux';
import IntakeFrame from './IntakeFrame';
import { intakeReducer, mapDataToInitialIntake } from './reducers/intake';
import { rampElectionReducer, mapDataToInitialRampElection } from './reducers/rampElection';
import { rampRefilingReducer, mapDataToInitialRampRefiling } from './reducers/rampRefiling';
import { supplementalClaimReducer, mapDataToInitialSupplementalClaim } from './reducers/supplementalClaim';
import ReduxBase from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/ReduxBase';

const reducer = combineReducers({
  intake: intakeReducer,
  rampElection: rampElectionReducer,
  rampRefiling: rampRefilingReducer,
  supplementalClaim: supplementalClaimReducer
});

class Intake extends React.PureComponent {
  render() {
    const initialState = {
      intake: mapDataToInitialIntake(this.props),
      rampElection: mapDataToInitialRampElection(this.props),
      rampRefiling: mapDataToInitialRampRefiling(this.props),
      supplementalClaim: mapDataToInitialSupplementalClaim(this.props)
    };

    return <ReduxBase initialState={initialState} reducer={reducer} analyticsMiddlewareArgs={['intake']}>
      <IntakeFrame {...this.props} />
    </ReduxBase>;
  }
}

export default Intake;
