import React, { PureComponent } from 'react';
import { formatDateStr } from '../util/DateUtil';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import _ from 'lodash';
import IssueList from './IssueList';

import LoadingMessage from '../components/LoadingMessage';
import { getClaimTypeDetailInfo } from '../reader/utils';
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
          <strong>Veteran ID:</strong> {appeal.vbms_id}
        </p>
        <p className="cf-pdf-meta-title">
          <strong>Type:</strong> {appeal.type} {getClaimTypeDetailInfo(appeal)}
        </p>
        <p className="cf-pdf-meta-title">
          <strong>Docket Number:</strong> {appeal.docket_number}
        </p>
        <p className="cf-pdf-meta-title">
          <strong>Regional Office:</strong> {`${appeal.regional_office.key} - ${appeal.regional_office.city}`}
        </p>
        <div className="cf-pdf-meta-title">
          <strong>Issues:</strong> {_.size(appeal.issues) ?
            <ol className="cf-pdf-meta-doc-info-issues">
              <IssueList appeal={appeal} />
            </ol> :
            'No issues on appeal'
          }
        </div>
      </div>;
    }

    return <div className="cf-sidebar-document-information">
      <p className="cf-pdf-meta-title cf-pdf-cutoff">
        <strong>Document Type: </strong>
        <span title={this.props.doc.type} className="cf-document-type">
          {this.props.doc.type}
        </span>
      </p>
      <p className="cf-pdf-meta-title">
        <strong>Receipt Date:</strong> {formatDateStr(this.props.doc.receivedAt)}
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
  didLoadAppealFail: state.readerReducer.didLoadAppealFail
});

export default connect(
  mapStateToProps
)(SideBarDocumentInformation);


