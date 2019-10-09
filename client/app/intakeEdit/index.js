import React from 'react';
import ReduxBase from '../components/ReduxBase';
import { intakeEditReducer, mapDataToInitialState } from './reducers';
import IntakeEditFrame from './IntakeEditFrame';

class IntakeEdit extends React.PureComponent {
  render() {
    const initialState = mapDataToInitialState(this.props);

    return <ReduxBase initialState={initialState} reducer={intakeEditReducer} analyticsMiddlewareArgs={['intakeEdit']}>
      <IntakeEditFrame {...this.props} />
    </ReduxBase>;
  }
}

export default IntakeEdit;
