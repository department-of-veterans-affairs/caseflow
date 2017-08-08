import React, { PureComponent } from 'react';
import { formatDateStr } from '../util/DateUtil';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import _ from 'lodash';

import LoadingMessage from '../components/LoadingMessage';
import Alert from '../components/Alert';

class SideBarDocumentInformation extends PureComponent {
  render() {
    const { appeal } = this.props;
    let renderComponent;

    const reload = () => {
      window.location.href = window.location.href;
    };

    if (this.props.didLoadAppealFail) {
      renderComponent = <Alert
        title="Unable to retrieve claim details"
        type="error">
        Please <a href="#" onClick={reload}>
        refresh this page</a> or try again later.
      </Alert>;
    } else if (_.isEmpty(appeal)) {
      renderComponent = <LoadingMessage message="Loading details..."/>;
    } else {
      renderComponent = <div>
        <p className="cf-pdf-meta-title">
          <b>Veteran ID:</b> {appeal.vbms_id}
        </p>
        <p className="cf-pdf-meta-title">
          <b>Type:</b> {appeal.type}
        </p>
        <p className="cf-pdf-meta-title">
          <b>Docket Number:</b> {appeal.docket_number}
        </p>
        <p className="cf-pdf-meta-title">
          <b>Regional Office:</b> {`${appeal.regional_office.key} - ${appeal.regional_office.city}`}
        </p>
        <div className="cf-pdf-meta-title">
          <b>Issues:</b> {_.size(appeal.issues) ?
            <ol className="cf-pdf-meta-doc-info-issues">
              {appeal.issues.map((issue) =>
                <li key={`${issue.appeal_id}_${issue.vacols_sequence_id}`}>
                  <span>
                    {issue.type.label}: {issue.levels ? issue.levels.join(', ') : ''}
                  </span>
                </li>
              )}
            </ol> :
            'No issues on appeal'
          }
        </div>
      </div>;
    }

    return <div className="cf-sidebar-document-information">
      <p className="cf-pdf-meta-title cf-pdf-cutoff">
        <b>Document Type: </b>
        <span title={this.props.doc.type} className="cf-document-type">
          {this.props.doc.type}
        </span>
      </p>
      <p className="cf-pdf-meta-title">
        <b>Receipt Date:</b> {formatDateStr(this.props.doc.receivedAt)}
      </p>
      <hr />
      {renderComponent}
    </div>;
  }
}

SideBarDocumentInformation.propTypes = {
  appeal: PropTypes.object.isRequired
};

const mapStateToProps = (state) => ({
  didLoadAppealFail: state.didLoadAppealFail
});

export default connect(
  mapStateToProps
)(SideBarDocumentInformation);


