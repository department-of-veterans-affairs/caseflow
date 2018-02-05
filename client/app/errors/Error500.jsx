import React from 'react';

class Error500 extends React.PureComponent {

  render() {
    return <div className="cf-txt-c cf-app-segment cf-app-segment--alt">
      <h1 className="cf-red-text cf-msg-screen-heading">Something went wrong.</h1>
      <p className="cf-msg-screen-text">
          If you continue to see this page, please contact the help desk.</p>
    </div>;

  }
}

export default Error500;
