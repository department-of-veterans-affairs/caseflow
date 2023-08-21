import _ from 'lodash';
import moment from 'moment';
import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import Alert from '../components/Alert';
import { css } from 'glamor';

const CACHE_TIMEOUT_HOURS = 3;

const alertStyling = css({
  marginBottom: '20px'
});

class LastRetrievalAlert extends React.PureComponent {
  render() {
    // Check if user has efolder express access
    const efolderExpressMessage = (this.props.userCanDownloadEfolder && this.props.efolderExpressUrl) ?
      <>
        Please visit <a href={this.props.efolderExpressUrl}
          target="_blank" rel="noopener noreferrer">eFolder Express</a>
        to fetch the latest list of documents.
      </> :
      <>
        Please contact the Caseflow team via the VA Enterprise Service Desk at 855-673-4357 or by creating a ticket
        via <a href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer">YourIT</a>.
      </>;

    // Check that document manifests have been recieved from VBMS
    if (!this.props.manifestVbmsFetchedAt) {
      return <div {...alertStyling}>
        <Alert title="Error" type="error">
          Some of {this.props.appeal.veteran_full_name}'s documents are unavailable at the moment due to
          a loading error from their eFolder. As a result, you may be viewing a partial list of eFolder documents.
          <br />
          {efolderExpressMessage}
        </Alert>
      </div>;
    }

    const staleCacheTime = moment().subtract(CACHE_TIMEOUT_HOURS, 'h'),
      vbmsManifestTimestamp = moment(this.props.manifestVbmsFetchedAt, 'MM/DD/YY HH:mma Z');

    // Check that manifest results are fresh
    if (vbmsManifestTimestamp.isBefore(staleCacheTime)) {
      const now = moment(),
        vbmsDiff = now.diff(vbmsManifestTimestamp, 'hours');

      return <div {...alertStyling}>
        <Alert title="Warning" type="warning">
          Reader last synced the list of documents with {this.props.appeal.veteran_full_name}'s eFolder
          {vbmsDiff} hours ago. As a result, you may be viewing a partial list of eFolder documents.
          <br />
          {efolderExpressMessage}
        </Alert>
      </div>;
    }

    return null;
  }
}

LastRetrievalAlert.propTypes = {
  manifestVbmsFetchedAt: PropTypes.string,
  efolderExpressUrl: PropTypes.string,
  userCanDownloadEfolder: PropTypes.bool,
  appeal: PropTypes.object,
};

export default connect(
  (state) => _.pick(state.documentList, 'manifestVbmsFetchedAt')
)(LastRetrievalAlert);
