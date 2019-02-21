import React from 'react';
import { connect } from 'react-redux';

import LegacySelectDispositionsView from './LegacySelectDispositionsView';
import SelectDispositionsView from './SelectDispositionsView';

class SelectDispositionsContainer extends React.PureComponent {
  render = () => {
    const { appeal, ...otherProps } = this.props;

    if (!appeal.isLegacyAppeal) {
      return <SelectDispositionsView {...otherProps} />;
    }

    return <LegacySelectDispositionsView {...otherProps} />;
  };
}

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.stagedChanges.appeals[ownProps.appealId]
});

export default connect(mapStateToProps, null)(SelectDispositionsContainer);
