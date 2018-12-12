import React, { PureComponent } from 'react';
import Alert from '../components/Alert';

export default class DocumentRetrevalAlert extends PureComponent {
  render() {
    if (!this.props.manifestVbmsFetchedAt || !this.props.manifestVvaFetchedAt) {
      return <Alert title="Error" type="error">
        Some documents could not be loaded at this time
      </Alert>;
    }

    let cacheTimeoutHours = 3,
        timeoutTimestamp = new Date();
    timeoutTimestamp.setHours(timeoutTimestamp.getHours() - cacheTimeoutHours);

    if (this.props.manifestVbmsFetchedAt < timeoutTimestamp.getTime() || 
      this.props.manifestVvaFetchedAt < timeoutTimestamp.getTime()) {
      return <Alert title="Warning" type="warning">
        The document list may be stale
      </Alert>;
    }

    return null;
  }
}
