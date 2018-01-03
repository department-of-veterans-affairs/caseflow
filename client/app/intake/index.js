import React from 'react';
import { combineReducers } from 'redux';
import IntakeFrame from './IntakeFrame';
import { intakeReducer, mapDataToInitialIntake } from './reducers/intake';
import { rampElectionReducer, mapDataToInitialRampElection } from './reducers/rampElection';
import { rampRefilingReducer, mapDataToInitialRampRefiling } from './reducers/rampRefiling';
import ReduxBase from '../util/ReduxBase';

class Intake extends React.PureComponent {
  componentWillMount() {
    const reducer = combineReducers({
      intake: intakeReducer,
      rampElection: rampElectionReducer,
      rampRefiling: rampRefilingReducer
    });

    this.setState({ reducer });
  }

  render() {
    const initialState = {
      intake: mapDataToInitialIntake(this.props),
      rampElection: mapDataToInitialRampElection(this.props),
      rampRefiling: mapDataToInitialRampRefiling(this.props)
    };

    return <ReduxBase initialState={initialState} reducer={this.state.reducer} analyticsMiddlewareArgs={['intake']}>
      <IntakeFrame {...this.props} />
    </ReduxBase>;
  }
}

export default Intake;

// if (module.hot) {
//   // Enable Webpack hot module replacement for reducers
//   module.hot.accept([
//     './reducers/intake',
//     './reducers/rampElection',
//     './reducers/rampRefiling'
//   ],
//   () => store.replaceReducer(reducer)
//   );
// }

