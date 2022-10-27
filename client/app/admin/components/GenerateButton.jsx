import React from 'react';
// import PropTypes from 'prop-types';
import Button from '../../components/Button';
// import { toggleCancelModal as toggleCancelModalAction } from '../actions/intake';
// import { REQUEST_STATE } from '../constants';
// import { connect } from 'react-redux';
// import { bindActionCreators } from 'redux';

class GenerateButton extends React.PureComponent {
  render = () => {
    const {
      // electionLoading,
      // refilingLoading,
      // toggleCancelModal,
      ...btnProps
    } = this.props;

    return (
      <Button
        id="generate-extract"
        linkStyling
        willNeverBeLoading
        // disabled={electionLoading || refilingLoading}
        // onClick={toggleCancelModal}
        {...btnProps}
      >
        Generate
      </Button>
    );
  };
}
GenerateButton.propTypes = {
  // electionLoading: PropTypes.bool,
  // refilingLoading: PropTypes.bool,
  // toggleCancelModal: PropTypes.func,
};

// const ConnectedCancelButton = connect(
//   () => ({
//     electionLoading:
//       rampElection.requestStatus.completeIntake === REQUEST_STATE.IN_PROGRESS,
//     refilingLoading:
//       rampRefiling.requestStatus.completeIntake === REQUEST_STATE.IN_PROGRESS,
//   }),
//   (dispatch) =>
//     bindActionCreators(
//       {
//         toggleCancelModal: toggleCancelModalAction,
//       },
//       dispatch
//     )
// )(GenerateButton);

// export default ConnectedCancelButton;
export default GenerateButton;
