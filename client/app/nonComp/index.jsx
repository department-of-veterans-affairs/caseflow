import React from 'react';
import ReduxBase from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/ReduxBase';
import { nonCompReducer, mapDataToInitialState } from './reducers';
import NonCompTabs from './components/NonCompTabs.jsx';


class NonComp extends React.PureComponent {
  render() {
    const initialState = mapDataToInitialState(this.props);

    return <ReduxBase initialState={initialState} reducer={nonCompReducer} analyticsMiddlewareArgs={['intakeEdit']}>
      <h1>Name of Business Line</h1>
      <h2>Reviews needing action</h2>
      <p>Review each issue and select a disposition</p>
      { NonCompTabs }
    </ReduxBase>;
  }
}

export default NonComp;
