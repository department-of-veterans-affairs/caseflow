import React from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

class Error500 extends React.PureComponent {

  render() {
    return <AppSegment filledBackground>
      <h1 className="cf-red-text cf-msg-screen-heading">Something went wrong.</h1>
      <p className="cf-msg-screen-text">
          If you continue to see this page, please contact the help desk.</p>
    </AppSegment>;
  }
}

export default Error500;
