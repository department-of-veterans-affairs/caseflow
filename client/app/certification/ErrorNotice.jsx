import React from 'react';
import { connect } from 'react-redux';

const UnconnectedErrorNotice = ({
  error
}) => {

  let message;

  const vbmsMessage = <main className="usa-grid">
                    <div className="cf-app">
                      <div className="cf-txt-c cf-app-segment cf-app-segment--alt">
                        <h1 className="cf-red-text cf-msg-screen-heading">VBMS Failure</h1>
                        <h2 className="cf-msg-screen-deck">Unable to communicate with the VBMS system at this time.</h2>
                        <p className="cf-msg-screen-text"> Please give VBMS a few moments to come back online, then
                          <a href=""> refresh this page. </a>
                          If you continue to see this page, please contact the help desk.
                        </p>
                      </div>
                    </div>
                  </main>;

  const defaultMessage = <main className="usa-grid">
                        <div className="cf-app">
                          <div className="cf-txt-c cf-app-segment cf-app-segment--alt">
                            <h1 className="cf-red-text cf-msg-screen-heading">Something went wrong.</h1>
                            <p className="cf-msg-screen-text">
                              If you continue to see this page, please contact the help desk.
                            </p>
                          </div>
                        </div>
                      </main>;

  switch (error) {
  case 'vbms_error':
    message = vbmsMessage;
    break;
  default:
    message = defaultMessage;
  }

  return message;
};

const mapStateToProps = (state) => ({
  error: state.error
});

const ErrorNotice = connect(
  mapStateToProps
)(UnconnectedErrorNotice);

export default ErrorNotice;
