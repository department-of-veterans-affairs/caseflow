import React from 'react';
import ReduxBase from '../components/ReduxBase';
import { combineReducers } from 'redux';
import index from './reducers';
import AdminApp from './pages/AdminApp';
import { Router } from 'react-router';
import { createBrowserHistory } from 'history';
import {
  featureToggleReducer,
  mapDataToFeatureToggle,
} from './reducers/featureToggle';

const history = createBrowserHistory();

export const reducer = combineReducers({
  index: index,
  featureToggles: featureToggleReducer,
});

export const generateInitialState = (props) => ({
  featureToggles: mapDataToFeatureToggle(props)
});
const initialState = generateInitialState(this.props);

const Admin = (props) => {
  return (
    <ReduxBase
      reducer={reducer}
      initialState={initialState}

    >
      <Router history={history}>
        <AdminApp {...props} />
      </Router>
    </ReduxBase>
  );
};

export default Admin;
