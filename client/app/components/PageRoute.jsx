import React from 'react';
import { Route } from 'react-router-dom';
import PropTypes from 'prop-types';

// Route augmented with application specific callbacks to change
// the page title and call google analytics
class PageRoute extends React.Component {
  static contextTypes = {
    router: PropTypes.shape({
      route: PropTypes.shape({
        location: PropTypes.object.isRequired,
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
  }

  // Only run callback if the location is changing. See if location has changed by
  // looking at the router here.
  componentWillReceiveProps(nextProps, nextContext) {
    const currentLocation = this.context.router.route.location;
    const nextLocation = nextContext.router.route.location;

    this.locationChanging = currentLocation != nextLocation
  }

  renderWithCallback() {
    const { title, render } = this.props;
    const locationChanging = this.locationChanging;

    return (params) => {
      if(locationChanging) {
        document.title = title;

        if (window.analyticsPageView) {
          window.analyticsPageView(window.location.pathname);
        }
      }

      return render(params);
    };
  }

  render() {
    // eslint-disable-next-line no-unused-vars
    let { title, render, ...routeProps } = this.props;

    return <Route { ...routeProps } render={ this.renderWithCallback() } />;
  }
}

export default PageRoute;
