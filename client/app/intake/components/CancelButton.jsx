import React from 'react';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import { toggleCancelModal as toggleCancelModalAction } from '../actions/intake';
import { REQUEST_STATE } from '../constants';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

class CancelButton extends React.PureComponent {
  render = () => {
    const {
      electionLoading,
      refilingLoading,
      toggleCancelModal,
      ...btnProps
    } = this.props;

    return (
      <Button
        id="cancel-intake"
        linkStyling
        willNeverBeLoading
        disabled={electionLoading || refilingLoading}
        onClick={toggleCancelModal}
        {...btnProps}
      >
        Cancel intake
      </Button>
    );
  };
}
CancelButton.propTypes = {
  electionLoading: PropTypes.bool,
  refilingLoading: PropTypes.bool,
  toggleCancelModal: PropTypes.func,
};

const ConnectedCancelButton = connect(
  ({ rampElection, rampRefiling }) => ({
    electionLoading:
      rampElection.requestStatus.completeIntake === REQUEST_STATE.IN_PROGRESS,
    refilingLoading:
      rampRefiling.requestStatus.completeIntake === REQUEST_STATE.IN_PROGRESS,
  }),
  (dispatch) =>
    bindActionCreators(
      {
        toggleCancelModal: toggleCancelModalAction,
      },
      dispatch
    )
)(CancelButton);

export default ConnectedCancelButton;
