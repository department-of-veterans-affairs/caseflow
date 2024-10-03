// External Dependencies
import PropTypes from 'prop-types';
import React from 'react';
import { matchPath, withRouter } from 'react-router';
import { Route } from 'react-router-dom';

// Local Dependencies
import LoadingScreen from 'app/components/LoadingScreen';
import { LOGO_COLORS } from 'app/constants/AppConstants';

// Wrapper around Route that adds dynamic page title and Analytics call
const ReaderRoute = (props) => {
  // eslint-disable-next-line no-unused-vars
  const { title, location, match, history, loading, loadingMessage, ...routeProps } = props;

  if (!matchPath(location.pathname, routeProps)) {
    return null;
  }

  if (!title) {
    throw new Error('PageRoute must implement `title`');
  }

  // Render the Loading Screen while the default route props are loading
  return loading ?
    <LoadingScreen
      spinnerColor={LOGO_COLORS[props.appName.toUpperCase()].ACCENT}
      message={loadingMessage}
    /> :
    <Route {...routeProps} />;
};

ReaderRoute.propTypes = {
  title: PropTypes.oneOfType([PropTypes.string, PropTypes.func]),
  render: PropTypes.func,
  component: PropTypes.elementType,
  match: PropTypes.object.isRequired,
  location: PropTypes.object.isRequired,
  history: PropTypes.object.isRequired,
  loading: PropTypes.bool,
  appName: PropTypes.string,
  loadingMessage: PropTypes.string
};

export default withRouter(ReaderRoute);
