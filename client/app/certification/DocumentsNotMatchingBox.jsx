import React, { PropTypes } from 'react';

// TODO: refactor to use shared components where necessary
export default class DocumentsNotMatchingBox extends React.Component {
  render() {
    return <div className="usa-alert usa-alert-error cf-app-segment" role="alert">
      <div className="usa-alert-body">
        <h3 className="usa-alert-heading">Cannot find documents in VBMS</h3>
        <p className="usa-alert-text">Some of the files listed in VACOLS could not be found in VBMS.</p>
      </div>
    </div>;
  }
}
