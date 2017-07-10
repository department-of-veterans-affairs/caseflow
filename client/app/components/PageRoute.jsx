import React from 'react';
import { Route } from 'react-router-dom';
import PropTypes from 'prop-types';
import Analytics from '../util/AnalyticsUtil';

// Route augmented with application specific callbacks to change
// the page title and call google analytics
class PageRoute extends React.Component {
  static contextTypes = {
    router: PropTypes.shape({
      route: PropTypes.shape({
        location: PropTypes.object.isRequired
      })
    })
  }

  constructor(props) {
    super(props);

    if (!props.title) {
      throw new Error('PageRoute must implement `pageTitle`');
    }

    if (!props.render) {
      throw new Error('PageRoute currently only works with `render`' +
                      '\n...feel free to add support for `component` and `children :)');
    }

    this.locationChanging = true;
  }

  // Only run callback if the location is changing. See if location has changed by
  // looking at the router here.
  componentWillReceiveProps(nextProps, nextContext) {
    const currentLocation = this.context.router.route.location.pathname;
    const nextLocation = nextContext.router.route.location.pathname;

    this.locationChanging = currentLocation !== nextLocation;
  }

  renderWithCallback = (params) => {
    const { title, render } = this.props;

    if (this.locationChanging) {
      document.title = title;
      Analytics.pageView(window.location.pathname);
    }

    return render(params);
  }

  render() {
    // eslint-disable-next-line no-unused-vars
    let { title, render, ...routeProps } = this.props;

    return <Route { ...routeProps } render={ this.renderWithCallback } />;
  }
}

export default PageRoute;
