import React from 'react';
import PropTypes from 'prop-types';
import { combineReducers } from 'redux';
// import IntakeFrame from './IntakeFrame';
// import { intakeReducer, mapDataToInitialIntake } from './reducers/intake';
import {
  featureToggleReducer,
  mapDataToFeatureToggle,
} from './reducers/featureToggles';
import Admin from './pages/Admin';
import { BrowserRouter } from 'react-router-dom';

export const reducer = combineReducers({
  intake: intakeReducer,
  featureToggles: featureToggleReducer,
});

export const generateInitialState = (props) => ({
  intake: mapDataToInitialIntake(props),
  featureToggles: mapDataToFeatureToggle(props),
});

class Admin extends React.PureComponent {
  componentDidMount() {
    if (window.Raven) {
      window.Raven.caseflowAppName = 'admin';
    }
  }

  render() {
    const initialState = generateInitialState(this.props);
    const Router = this.props.router || BrowserRouter;

    return (
      <ReduxBase
        initialState={initialState}
        reducer={reducer}
        analyticsMiddlewareArgs={['admin']}
      >
        <Router basename="/admin" {...this.props.routerTestProps}>
          <IntakeFrame {...this.props} />
        </Router>
      </ReduxBase>
    );
  }
}
Admin.propTypes = {
  router: PropTypes.object,
  routerTestProps: PropTypes.object,
};

export default Admin;
