import _ from 'lodash';
import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

class UnconnectedLastRetrievalInfo extends React.PureComponent {
  render() {
    return [
      this.props.manifestVbmsFetchedAt ?
        <div id="vbms-manifest-retrieved-at" key="vbms">
          Last synced with {this.props.appeal.veteran_full_name}'s eFolder: {this.props.manifestVbmsFetchedAt.slice(0, -5)}        </div> :
        <div className="cf-red-text" key="vbms">
          Unable to display eFolder documents at this time
        </div>
    ];
  }
}

UnconnectedLastRetrievalInfo.propTypes = {
  appeal: PropTypes.object,
  manifestVbmsFetchedAt: PropTypes.string,
};

export default connect(
  (state) => _.pick(state.documentList, ['manifestVbmsFetchedAt'])
)(UnconnectedLastRetrievalInfo);
