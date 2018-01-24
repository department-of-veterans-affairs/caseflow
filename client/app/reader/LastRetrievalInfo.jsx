import _ from 'lodash';
import React from 'react';
import { connect } from 'react-redux';

class UnconnectedLastRetrievalInfo extends React.PureComponent {
  render() {
    if (!this.props.manifestVbmsFetchedAt) {
      return null;
    }

    return [
      <div id="vbms-manifest-retrieved-at" key="vbms">Last VBMS retrieval: {this.props.manifestVbmsFetchedAt}</div>,
      this.props.manifestVvaFetchedAt ?
        <div id="vva-manifest-retrieved-at" key="vva">Last VVA retrieval: {this.props.manifestVvaFetchedAt}</div> :
        <div className="cf-red-text" key="vva">Unable to display VVA documents at this time</div>
    ];
  }
}

export default connect(
  (state) => _.pick(state.documentList, ['manifestVvaFetchedAt', 'manifestVbmsFetchedAt'])
)(UnconnectedLastRetrievalInfo);
