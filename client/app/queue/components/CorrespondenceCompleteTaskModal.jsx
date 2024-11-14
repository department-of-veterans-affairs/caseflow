import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';

import { taskById } from '../selectors';
import { requestPatch } from '../uiReducer/uiActions';
import { taskActionData } from '../utils';
import TextareaField from '../../components/TextareaField';
import COPY from '../../../COPY';
import TASK_STATUSES from '../../../constants/TASK_STATUSES';
import QueueFlowModal from './QueueFlowModal';
import {
  setTaskNotRelatedToAppealBanner,
  completeTaskNotRelatedToAppeal } from '../correspondence/correspondenceDetailsReducer/correspondenceDetailsActions';

/* eslint-disable camelcase */
const CorrespondenceCompleteTaskModal = (props) => {
  const taskData = taskActionData(props);

  const [instructions, setInstructions] = useState('');

  const submit = () => {

    const correspondence = props.correspondenceInfo;

    // eslint-disable-next-line no-shadow
    const updatedTask = correspondence.tasksUnrelatedToAppeal.find((task) =>
      parseInt(props.task_id, 10) === parseInt(task.uniqueId, 10));

    const payload = {
      data: {
        task: {
          status: TASK_STATUSES.completed,
          instructions,
          ...(taskData?.business_payloads && { business_payloads: taskData?.business_payloads })
        }
      }
    };

    const frontendParams = {
      taskId: props.task_id,
      taskName: updatedTask.label,
      teamName: updatedTask.assignedTo
    };

    // eslint-disable-next-line no-shadow
    const filteredTasks = props.correspondenceInfo.tasksUnrelatedToAppeal.filter((task) =>
      parseInt(task.uniqueId, 10) !== parseInt(props.task_id, 10));

    correspondence.tasksUnrelatedToAppeal = filteredTasks;

    updatedTask.status = TASK_STATUSES.completed;

    correspondence.closedTasksUnrelatedToAppeal.push(updatedTask);

    return props.completeTaskNotRelatedToAppeal(payload, frontendParams, correspondence);

  };

  // Additional properties - should be removed later once generic submit buttons are styled the same across all modals
  const modalProps = {};

  return (
    <QueueFlowModal
      {...modalProps}
      title={COPY.MARK_TASK_COMPLETE_TITLE}
      button={COPY.MARK_TASK_COMPLETE_BUTTON}
      pathAfterSubmit={taskData?.redirect_after ?? `/queue/correspondence/${props.correspondence_uuid}`}
      submit={submit}
    >
      {taskData?.modal_body &&
        <React.Fragment>
          <div dangerouslySetInnerHTML={{ __html: taskData.modal_body }} />
          <br />
        </React.Fragment>
      }
      <TextareaField
        name={taskData?.instructions_label ?? COPY.PLEASE_PROVIDE_CONTEXT_AND_INSTRUCTIONS_LABEL}
        id="taskInstructions"
        optional
        onChange={setInstructions}
        value={instructions}
      />
    </QueueFlowModal>
  );

};
/* eslint-enable camelcase */

CorrespondenceCompleteTaskModal.propTypes = {
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
  correspondenceInfo: state.correspondenceDetails.correspondenceInfo
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  setTaskNotRelatedToAppealBanner,
  completeTaskNotRelatedToAppeal
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(
    CorrespondenceCompleteTaskModal
  )
));
