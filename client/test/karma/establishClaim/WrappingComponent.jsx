import React from 'react';
import PropTypes from 'prop-types';
import { Provider } from 'react-redux';
import { BrowserRouter as Router } from 'react-router-dom';
import bootstrapRedux from '../../../app/establishClaim/reducers/bootstrap';
import { createStore } from 'redux';

const { initialState, reducer } = bootstrapRedux();
const defaultStore = createStore(reducer, initialState);

export { defaultStore as store };

export const WrappingComponent = ({ children, store }) => (
  <Provider store={store || defaultStore}>
    <Router>{children}</Router>
  </Provider>
);

WrappingComponent.propTypes = {
  children: PropTypes.node.isRequired,
  store: PropTypes.object
};
