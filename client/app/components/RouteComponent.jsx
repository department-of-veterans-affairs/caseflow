import React from 'react';

// Base class for 
class RouteComponent extends React.PureComponent {
  componentWillMount() {
    if(!this.pageTitle) {
      throw("RouteComponent must implement `pageTitle`")
    }

    document.title = this.pageTitle;
    analyticsPageView(window.location.pathname);
  }
}

export default RouteComponent;