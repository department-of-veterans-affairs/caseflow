import React from 'react';
import { withRouter } from 'react-router';

class CurrentLocation extends React.Component {
  pathCheck = (pathname) => {
    if (pathname.match(/worksheet/)) {
      return '| Daily Docket | Hearing Worksheet';
    } else if (pathname.match(/dockets\/[\d]+-[\d]+-[\d]+/)) {
      return '| Daily Docket';
    }

    return '';
  };

  render() {
    const {
      location
    } = this.props;

    return (
      <span>{this.pathCheck(location.pathname)}</span>
    );
  }
}

const Breadcrumb = withRouter(CurrentLocation);

export default Breadcrumb;
