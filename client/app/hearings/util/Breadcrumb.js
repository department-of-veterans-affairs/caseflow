import React from 'react';
import { withRouter } from 'react-router';

class CurrentLocation extends React.Component {
  render() {
    const pathCheck = (pathname) => {
      if (pathname.match(/\/[\d]+\//)) {
        return '| Daily Docket | Hearing Worksheet';
      } else if (pathname.match(/\/[\d]+-[\d]+-[\d]+/)) {
        return '| Daily Docket';
      }

      return '';
    };

    const {
      location
    } = this.props;

    return (
      <span>{pathCheck(location.pathname)}</span>
    );
  }
}

const Breadcrumb = withRouter(CurrentLocation);

export default Breadcrumb;
