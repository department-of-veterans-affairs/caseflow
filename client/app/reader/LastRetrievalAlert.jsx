import _ from 'lodash';
import moment from 'moment';
import React from 'react';
import { connect } from 'react-redux';
import Alert from '../components/Alert';
import { css } from 'glamor';

const CACHE_TIMEOUT_HOURS = 3;

const alertStyling = css({
  marginBottom: '20px'
});

class LastRetrievalAlert extends React.PureComponent {

  render() {

    // Check that document manifests have been recieved from VVA and VBMS
    if (!this.props.manifestVbmsFetchedAt || !this.props.manifestVvaFetchedAt) {
      return <div {...alertStyling}>
        <Alert title="Error" type="error">
          Some of {this.props.appeal.veteran_full_name}'s documents are not available at the moment due to
          a loading error from VBMS or VVA. As a result, you may be viewing a partial list of claims folder documents.
          <br />
          <br />
          Please refresh your browser at a later point to view a complete list of documents in the claims
          folder.
        </Alert>
      </div>;
    }

    const staleCacheTime = moment().subtract(CACHE_TIMEOUT_HOURS, 'h'),
      vbmsManifestTimestamp = moment(this.props.manifestVbmsFetchedAt, 'MM/DD/YY HH:mma Z'),
      vvaManifestTimestamp = moment(this.props.manifestVvaFetchedAt, 'MM/DD/YY HH:mma Z');

    // Check that manifest results are fresh
    if (vbmsManifestTimestamp.isBefore(staleCacheTime) || vvaManifestTimestamp.isBefore(staleCacheTime)) {
      const now = moment(),
        vbmsDiff = now.diff(vbmsManifestTimestamp, 'hours'),
        vvaDiff = now.diff(vvaManifestTimestamp, 'hours');

      return <div {...alertStyling}>
        <Alert title="Warning" type="warning">
          We last synced with VBMS and VVA {Math.max(vbmsDiff, vvaDiff)} hours ago. If you'd like to check for new
          documents, refresh the page.
        </Alert>
      </div>;
    }

    return null;
  }
}

export default connect(
  (state) => _.pick(state.documentList, ['manifestVvaFetchedAt', 'manifestVbmsFetchedAt'])
)(LastRetrievalAlert);
