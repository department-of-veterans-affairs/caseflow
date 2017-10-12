import React from 'react';
import Button from '../../components/Button';
import {toggleCancelModal} from '../redux/actions';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

class CancelButton extends React.PureComponent {
  render = () => 
    <Button 
      legacyStyling={false} 
      willNeverBeLoading 
      onClick={this.props.toggleCancelModal}
    >
      Cancel Intake
    </Button>
}

const ConnectedCancelButton = connect(
  null,
  (dispatch) => bindActionCreators({
    toggleCancelModal
  }, dispatch)
)(CancelButton)

export default ConnectedCancelButton
