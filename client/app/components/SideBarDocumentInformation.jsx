import React, { PureComponent } from 'react';
import { formatDateStr } from '../util/DateUtil';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import _ from 'lodash';

import LoadingMessage from '../components/LoadingMessage';
import Alert from '../components/Alert';
import { READER_COLOR } from '../reader/constants';

class SideBarDocumentInformation extends PureComponent {
  render() {
    const { appeal } = this.props;
    let appealInfo;

    if (this.props.didLoadAppealFail) {
      appealInfo = <Alert
        title="Unable to retrieve claims folder details"
        type="error">
        Caseflow is experiencing technical difficulties right now. 
        Please <a href={`/reader/appeal${this.props.history.location.pathname}${this.props.history.location.search}`}>
        refresh this page.</a> or try again later.
      </Alert>;
    } else if (_.isEmpty(appeal)) {
      appealInfo = <LoadingMessage message="Loading details..." spinnerColor={READER_COLOR}/>
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
    { appealInfo ?
    appealInfo :
    <div>
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
      <p className="cf-pdf-meta-title">
        <b>Issues</b>
        <ol>
          {appeal.issues.map((issue) =>
            <li key={`${issue.appeal_id}_${issue.vacols_sequence_id}`}><span>
              {issue.type.label}: {issue.levels ? issue.levels.join(', ') : ''}
            </span></li>
          )}
        </ol>
      </p>
    </div> }
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


