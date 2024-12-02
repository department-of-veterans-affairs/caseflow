import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';

import { taskById } from '../selectors';
import { requestPatch } from '../uiReducer/uiActions';
import { taskActionData } from '../utils';
import TASK_STATUSES from '../../../constants/TASK_STATUSES';
import COPY from '../../../COPY';
import QueueFlowModal from './QueueFlowModal';
import {
  createNewEvidenceWindowTask,
} from '../correspondence/correspondenceDetailsReducer/correspondenceDetailsActions';

/* eslint-disable camelcase */
const CorrespondenceRemoveWaiveEvidenceModal = (props) => {
  const { task, correspondenceInfo } = props;
  const taskData = taskActionData(props);
  const correspondence = correspondenceInfo;
  const submit = () => {
    const payload = {
      data: {
        appeal_uuid: props.appealId,
        task: {
          task_id: task.id,
          instructions: task.instructions,
          type: 'EvidenceSubmissionWindowTask',
          appeal_id: task.appealId,
          appeal_type: 'Correspondence',
          status: TASK_STATUSES.completed
        }
      }
    };

    return props.createNewEvidenceWindowTask(payload, correspondence, task.appealId);

  };

  const modalProps = {};

  return (
    <QueueFlowModal
      {...modalProps}
      title={COPY.CONFIRM_WAIVE_REMOVAL}
      button={COPY.MODAL_CONFIRM_BUTTON}
      pathAfterSubmit={`/queue/correspondence/${props.correspondence_uuid}`}
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
  createNewEvidenceWindowTask: PropTypes.func,
  task: PropTypes.shape({
    appeal: PropTypes.shape({
      hasCompletedSctAssignTask: PropTypes.bool
    }),
    assignedTo: PropTypes.shape({
      type: PropTypes.string
    }),
    appealId: PropTypes.string,
    id: PropTypes.string,
    instructions: PropTypes.string,
    uniqueId: PropTypes.string,
    type: PropTypes.string,
    label: PropTypes.string,
    onHoldDuration: PropTypes.number
  }),
  task_id: PropTypes.string,
  correspondence_uuid: PropTypes.string,
  team: PropTypes.string,
  correspondenceInfo: PropTypes.func,
  appealId: PropTypes.string,
};

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  correspondenceInfo: state.correspondenceDetails.correspondenceInfo,
  showActionsDropdown: state.correspondenceDetails.showActionsDropdown,
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  createNewEvidenceWindowTask,

}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(
    CorrespondenceRemoveWaiveEvidenceModal
  )
));
