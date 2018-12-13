import _ from 'lodash';
import moment from 'moment';
import React from 'react';
import { connect } from 'react-redux';
import Alert from '../components/Alert';

const CACHE_TIMEOUT_HOURS = 3;
const TIMEZONES = {
  ' GMT': ' +0000',
  ' EDT': ' -0400',
  ' EST': ' -0500',
  ' CDT': ' -0500',
  ' CST': ' -0600',
  ' MDT': ' -0600',
  ' MST': ' -0700',
  ' PDT': ' -0700',
  ' PST': ' -0800'
};

class LastRetrievalAlert extends React.PureComponent {

  render() {

    // Check that document manifests have been recieved from VVA and VBMS
    if (!this.props.manifestVbmsFetchedAt || !this.props.manifestVvaFetchedAt) {
      return <Alert title="Error" type="error">
        Some documents could not be loaded at this time...
      </Alert>;
    }

    let staleCacheTime = new Date();

    staleCacheTime.setHours(staleCacheTime.getHours() - CACHE_TIMEOUT_HOURS);

    let staleCacheTimestamp = staleCacheTime.getTime() / 1000,
      vbmsManifestTimeString = this.props.manifestVbmsFetchedAt,
      vvaManifestTimeString = this.props.manifestVvaFetchedAt;

    let parsableVbmsManifestTimeString = vbmsManifestTimeString.slice(0, -4) +
      TIMEZONES[vbmsManifestTimeString.slice(-4)],
      parsableVvaManifestTimeString = vvaManifestTimeString.slice(0, -4) +
        TIMEZONES[vvaManifestTimeString.slice(-4)],
      vbmsManifestTimestamp = moment(parsableVbmsManifestTimeString, 'MM/DD/YY HH:mma Z').unix(),
      vvaManifestTimestamp = moment(parsableVvaManifestTimeString, 'MM/DD/YY HH:mma Z').unix();

    // Check that manifest results are fresh
    if (vbmsManifestTimestamp < staleCacheTimestamp || vvaManifestTimestamp < staleCacheTimestamp) {
      return <Alert title="Warning" type="warning">
        The document list may be stale
      </Alert>;
    }

    return null;
  }
}

export default connect(
  (state) => _.pick(state.documentList, ['manifestVvaFetchedAt', 'manifestVbmsFetchedAt'])
)(LastRetrievalAlert);
