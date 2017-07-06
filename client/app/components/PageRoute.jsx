import React from 'react';
import { Route } from 'react-router-dom';

// Route augmented with application specific callbacks to change
// the page title and call google analytics
class PageRoute extends React.Component {
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

  renderWithCallback() {
    const { title, render } = this.props;

    return (params) => {
      document.title = title;

      if (window.analyticsPageView) {
        window.analyticsPageView(window.location.pathname);
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
