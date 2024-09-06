import React from 'react';
import FlowModal from '../../components/FlowModal';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';

import { highlightInvalidFormItems, resetSaveState } from '../uiReducer/uiActions';

const QueueFlowModal = (props) => {
  return (
    <FlowModal {...props} />
  );
};

const mapStateToProps = (state) => ({
  saveSuccessful: state.ui.saveState.saveSuccessful,
  success: state.ui.messages.success,
  error: state.ui.messages.error
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      highlightInvalidFormItems,
      resetSaveState
    },
    dispatch
  );

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(QueueFlowModal)
);
