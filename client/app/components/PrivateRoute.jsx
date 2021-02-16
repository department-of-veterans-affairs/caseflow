import React from 'react';
import PropTypes from 'prop-types';
import { Redirect } from 'react-router';

// Wrapper around Route that adds dynamic page title and Analytics call
export const PrivateRoute = ({ children, authorized, redirectTo }) =>
  authorized ? children : <Redirect to={redirectTo} />;

PrivateRoute.propTypes = {
  redirectTo: PropTypes.string,
  children: PropTypes.element,
  authorized: PropTypes.bool,
};

export default PrivateRoute;
