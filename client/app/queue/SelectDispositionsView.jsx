import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import LegacySelectDispositionsView from './LegacySelectDispositionsView';
import AmaSelectDispositionsView from './AmaSelectDispositionsView';

class SelectDispositionsView extends React.PureComponent {
  render = () => {
    const { appeal, featureToggles, ...otherProps } = this.props;

    if (appeal.isLegacy || !featureToggles.ama_decision_issues) {
      return <LegacySelectDispositionsView {...otherProps} />;
    } else {
      return <AmaSelectDispositionsView {...otherProps}/>;
    }
  };
}

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.stagedChanges.appeals[ownProps.appealId],
  featureToggles: state.ui.featureToggles
});

export default connect(mapStateToProps, null)(SelectDispositionsView);
