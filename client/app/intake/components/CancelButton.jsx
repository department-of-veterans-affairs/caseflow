import React from 'react';
import Button from '../../components/Button';
import { toggleCancelModal } from '../actions/common';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

class CancelButton extends React.PureComponent {
  render = () =>
    <Button
      id="cancel-intake"
      legacyStyling={false}
      linkStyling
      willNeverBeLoading
      onClick={this.props.toggleCancelModal}
    >
      Cancel intake
    </Button>
}

const ConnectedCancelButton = connect(
  null,
  (dispatch) => bindActionCreators({
    toggleCancelModal
  }, dispatch)
)(CancelButton);

export default ConnectedCancelButton;
