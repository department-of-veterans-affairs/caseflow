import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';

import { taskById } from '../selectors';
import { requestPatch } from '../uiReducer/uiActions';
import { taskActionData } from '../utils';
import COPY from '../../../COPY';
import QueueFlowModal from './QueueFlowModal';
import {
  setTaskNotRelatedToAppealBanner,
  completeTaskNotRelatedToAppeal } from '../correspondence/correspondenceDetailsReducer/correspondenceDetailsActions';

/* eslint-disable camelcase */
const CorrespondenceRemoveWaiveEvidenceModal = (props) => {
  const taskData = taskActionData(props);

  const submit = () => {
    const correspondence = props.correspondenceInfo;

  };

  const modalProps = {};

  return (
    <QueueFlowModal
      {...modalProps}
      title={COPY.CONFIRM_WAIVE_REMOVAL}
      button={COPY.MODAL_CONFIRM_BUTTON}
      pathAfterSubmit={taskData?.redirect_after ?? `/queue/correspondence/${props.correspondence_uuid}`}
      submit={submit}
    >
      {taskData?.modal_body &&
        <React.Fragment>
          <div dangerouslySetInnerHTML={{ __html: taskData.modal_body }} />
        </React.Fragment>
      }
    </QueueFlowModal>
  );

};
/* eslint-enable camelcase */

CorrespondenceRemoveWaiveEvidenceModal.propTypes = {
  requestPatch: PropTypes.func,
  completeTaskNotRelatedToAppeal: PropTypes.func,
  task: PropTypes.shape({
    appeal: PropTypes.shape({
      hasCompletedSctAssignTask: PropTypes.bool
    }),
    assignedTo: PropTypes.shape({
      type: PropTypes.string
    }),
    taskId: PropTypes.string,
    uniqueId: PropTypes.string,
    type: PropTypes.string,
    label: PropTypes.string,
    onHoldDuration: PropTypes.number
  }),
  task_id: PropTypes.string,
  correspondence_uuid: PropTypes.string,
  correspondenceInfo: PropTypes.func,
  team: PropTypes.string
};

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  taskNotRelatedToAppealBanner: state.correspondenceDetails.bannerAlert,
  correspondenceInfo: state.correspondenceDetails.correspondenceInfo,
  showActionsDropdown: state.correspondenceDetails.showActionsDropdown,
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  setTaskNotRelatedToAppealBanner,
  completeTaskNotRelatedToAppeal
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(
    CorrespondenceRemoveWaiveEvidenceModal
  )
));
