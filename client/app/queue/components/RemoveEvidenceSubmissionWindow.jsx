import React, { useState, useEffect } from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import QueueFlowModal from './QueueFlowModal';

/* eslint-disable camelcase */
const RemoveEvidenceSubmissionWindow = (props) => {

  return (
    <QueueFlowModal
      title="Assign task"
      button="Assign task"
    >
    </QueueFlowModal>
  );
};
/* eslint-enable camelcase */

RemoveEvidenceSubmissionWindow.propTypes = {

};

const mapStateToProps = (state, ownProps) => ({

});

const mapDispatchToProps = (dispatch) => bindActionCreators({

}, dispatch);

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(RemoveEvidenceSubmissionWindow)
);
