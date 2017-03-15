import React, { PropTypes } from 'react';

// TODO: refactor to use shared components if helpful
export default class DocumentsMatchingBox extends React.Component {
  render() {
    return <div className="usa-alert cf-app-segment usa-alert-success">
      <div className="usa-alert-body">
        <h3 className="usa-alert-heading">All documents detected! </h3>
        <p className="usa-alert-text">The Form 9, NOD, SOC, and SSOCs (if applicable) were found in the eFolder.</p>
      </div>
    </div>;
  }
}
