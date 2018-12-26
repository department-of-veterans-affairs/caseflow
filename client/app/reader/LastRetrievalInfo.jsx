import _ from 'lodash';
import React from 'react';
import { connect } from 'react-redux';

class UnconnectedLastRetrievalInfo extends React.PureComponent {
  render() {
    return [
      this.props.manifestVbmsFetchedAt ?
        <div id="vbms-manifest-retrieved-at" key="vbms">
          Last VBMS retrieval: {this.props.manifestVbmsFetchedAt.slice(0, -5)}
        </div> :
        <div className="cf-red-text" key="vbms">
          Unable to display VBMS documents at this time
        </div>,
      this.props.manifestVvaFetchedAt ?
        <div id="vva-manifest-retrieved-at" key="vva">
          Last VVA retrieval: {this.props.manifestVvaFetchedAt.slice(0, -5)}
        </div> :
        <div className="cf-red-text" key="vva">
          Unable to display VVA documents at this time
        </div>
    ];
  }
}

export default connect(
  (state) => _.pick(state.documentList, ['manifestVvaFetchedAt', 'manifestVbmsFetchedAt'])
)(UnconnectedLastRetrievalInfo);
