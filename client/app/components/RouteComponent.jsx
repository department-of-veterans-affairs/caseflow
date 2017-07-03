import React from 'react';

// Base class for a component that is acts as the endpoint
// for a react route.
class RouteComponent extends React.PureComponent {
  componentWillMount() {
    if (!this.pageTitle) {
      throw new Error('RouteComponent must implement `pageTitle`');
    }

    document.title = this.pageTitle;
    window.analyticsPageView(window.location.pathname);
  }
}

export default RouteComponent;
