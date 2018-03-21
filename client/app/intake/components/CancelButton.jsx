import React from 'react';
import Button from '../../components/Button';
import { toggleCancelModal } from '../actions/common';
import { REQUEST_STATE } from '../constants';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

class CancelButton extends React.PureComponent {
  render = () =>
    <Button
      id="cancel-intake"
      legacyStyling={false}
      linkStyling
      willNeverBeLoading
      disabled={this.props.electionLoading || this.props.refilingLoading}
      onClick={this.props.toggleCancelModal}
    >
      Cancel intake
    </Button>
}

const ConnectedCancelButton = connect(
  ({ rampElection, rampRefiling, intake }) => ({
    formType: intake.formType,
    electionLoading: rampElection.requestStatus.completeIntake === REQUEST_STATE.IN_PROGRESS,
    refilingLoading: rampRefiling.requestStatus.completeIntake === REQUEST_STATE.IN_PROGRESS
  }),
  (dispatch) => bindActionCreators({
    toggleCancelModal
  }, dispatch)
)(CancelButton);

export default ConnectedCancelButton;
