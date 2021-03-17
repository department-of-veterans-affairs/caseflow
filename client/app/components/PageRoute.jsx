// External Dependencies
import React, { useEffect } from 'react';
import { Route } from 'react-router-dom';
import PropTypes from 'prop-types';
import { isFunction } from 'lodash';
import { withRouter, matchPath } from 'react-router';

// Local Dependencies
import { LOGO_COLORS } from 'app/constants/AppConstants';
import LoadingScreen from 'app/components/LoadingScreen';

// Wrapper around Route that adds dynamic page title and Analytics call
const PageRoute = (props) => {
  // eslint-disable-next-line no-unused-vars
  const { title, location, match, history, loading, loadingMessage, ...routeProps } = props;

  if (!matchPath(location.pathname, routeProps)) {
    return null;
  }

  if (!title) {
    throw new Error('PageRoute must implement `title`');
  }

  // Update title and analytics (only) when location changes
  useEffect(() => {
    document.title = isFunction(title) ? title(props) : title;

    window.analyticsPageView(window.location.pathname);
  }, [history.location]);

  // Render the Loading Screen while the default route props are loading
  return loading ?
    <LoadingScreen spinnerColor={LOGO_COLORS[props.appName.toUpperCase()].ACCENT} message={loadingMessage} /> :
    <Route {...routeProps} />;
};

PageRoute.propTypes = {
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

export default withRouter(PageRoute);
