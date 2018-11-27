import React from 'react';
import { connect } from 'react-redux';

import LegacySelectDispositionsView from './LegacySelectDispositionsView';
import SelectDispositionsView from './SelectDispositionsView';

class SelectDispositionsContainer extends React.PureComponent {
  render = () => {
    const { appeal, featureToggles, ...otherProps } = this.props;

    if (appeal.isLegacy || !featureToggles.ama_decision_issues) {
      return <LegacySelectDispositionsView {...otherProps} />;
    }

    return <SelectDispositionsView {...otherProps} />;

  };
}

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.stagedChanges.appeals[ownProps.appealId],
  featureToggles: state.ui.featureToggles
});

export default connect(mapStateToProps, null)(SelectDispositionsContainer);
