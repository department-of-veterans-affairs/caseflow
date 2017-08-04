import React from 'react';
import { Route } from 'react-router-dom';
import PropTypes from 'prop-types';

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
      throw new Error('PageRoute must implement `title`');
    }

    if (!props.render && !props.component) {
      throw new Error('PageRoute currently only works with `render` and `component`' +
                      '\n...feel free to add support for `children` :)');
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
    const { title, render, component } = this.props;

    if (this.locationChanging) {
      document.title = title;
      window.analyticsPageView(window.location.pathname);
    }

    return component ? React.createElement(component, params) : render(params);
  }

  render() {
    // eslint-disable-next-line no-unused-vars
    let { title, render, component, ...routeProps } = this.props;

    return <Route { ...routeProps } render={ this.renderWithCallback } />;
  }
}

export default PageRoute;
