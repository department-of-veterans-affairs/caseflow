import _ from 'lodash';
import React from 'react';
import { connect } from 'react-redux';

class UnconnectedLastRetrievalInfo extends React.PureComponent {
  render() {
    return [
      this.props.manifestVbmsFetchedAt ?
        <div id="vbms-manifest-retrieved-at" key="vbms">
          Last synced with {this.props.appeal.veteran_full_name}'s eFolder: {this.props.manifestVbmsFetchedAt.slice(0, -5)}
        </div> :
        <div className="cf-red-text" key="vbms">
          Unable to display eFolder documents at this time
        </div>
    ];
  }
}

export default connect(
  (state) => _.pick(state.documentList, 'manifestVbmsFetchedAt')
)(UnconnectedLastRetrievalInfo);
