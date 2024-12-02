import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { get } from 'lodash';

import { taskById } from '../selectors';
import { requestPatch } from '../uiReducer/uiActions';
import { taskActionData } from '../utils';
import TextareaField from '../../components/TextareaField';
import COPY from '../../../COPY';
import TASK_STATUSES from '../../../constants/TASK_STATUSES';
import QueueFlowModal from './QueueFlowModal';
import {
  setTaskNotRelatedToAppealBanner,
  cancelTaskNotRelatedToAppeal,
} from '../correspondence/correspondenceDetailsReducer/correspondenceDetailsActions';

/* eslint-disable camelcase */
const CorrespondenceCancelTaskModal = (props) => {
  const { task } = props;
  const taskData = taskActionData(props);

  // Show task instructions by default
  const shouldShowTaskInstructions = get(taskData, 'show_instructions', true);

  const [instructions, setInstructions] = useState('');
  const [instructionsAdded, setInstructionsAdded] = useState(true);
  const tempTask = props.correspondenceInfo.tasksUnrelatedToAppeal.find(
    (task1) => parseInt(props.task_id, 10) === parseInt(task1.uniqueId, 10)
  );

  useEffect(() => {
    // Handle document search position
    if (instructions.length > 0) {
      setInstructionsAdded(false);
    } else {
      setInstructionsAdded(true);
    }
  }, [instructions]);

  const validateForm = () => {
    if (!shouldShowTaskInstructions) {
      return true;
    }

    return instructions.length > 0;
  };

  const submit = () => {

    const payload = {
      data: {
        task: {
          status: TASK_STATUSES.cancelled,
          instructions,
          ...(taskData?.business_payloads && { business_payloads: taskData?.business_payloads })
        }
      }
    };

    const filteredTasks = props.correspondenceInfo.tasksUnrelatedToAppeal.filter((filterdTask) =>
      parseInt(filterdTask.uniqueId, 10) !== parseInt(props.task_id, 10));

    const tempCor = props.correspondenceInfo;

    tempCor.tasksUnrelatedToAppeal = filteredTasks;

    return props.cancelTaskNotRelatedToAppeal(props.task_id, tempTask.label, tempTask.assignedTo, tempCor, payload);

  };

  // Additional properties - should be removed later once generic submit buttons are styled the same across all modals
  const modalProps = {};

  if ([
    'AssessDocumentationTask',
    'EducationAssessDocumentationTask',
    'HearingPostponementRequestMailTask'
  ].includes(task?.type) || task?.appeal.hasCompletedSctAssignTask) {
    modalProps.submitButtonClassNames = ['usa-button'];
    modalProps.submitDisabled = !validateForm();
  }

  return (
    <QueueFlowModal
      {...modalProps}
      title= "Cancel task"
      button="Cancel task"
      submitDisabled= {instructionsAdded}
      pathAfterSubmit={taskData?.redirect_after ?? `/queue/correspondence/${props.correspondence_uuid}`}
      submit={submit}
      validateForm={validateForm}
    >
      {shouldShowTaskInstructions &&
        <TextareaField
          name={taskData?.instructions_label ?? COPY.PLEASE_PROVIDE_CONTEXT_AND_INSTRUCTIONS_LABEL}
          id="cancelTaskInstructions"
          onChange={setInstructions}
          value={instructions}
        />
      }
    </QueueFlowModal>
  );

};
/* eslint-enable camelcase */

CorrespondenceCancelTaskModal.propTypes = {
  requestPatch: PropTypes.func,
  cancelTaskNotRelatedToAppeal: PropTypes.func,
  correspondenceInfo: PropTypes.object,
  task: PropTypes.shape({
    uniqueId: PropTypes.number,
    appeal: PropTypes.shape({
      hasCompletedSctAssignTask: PropTypes.bool
    }),
    assignedTo: PropTypes.shape({
      type: PropTypes.string
    }),
    taskId: PropTypes.string,
    type: PropTypes.string,
    onHoldDuration: PropTypes.number
  }),
  task_id: PropTypes.string,
  correspondence_uuid: PropTypes.number,
};

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  taskNotRelatedToAppealBanner: state.correspondenceDetails.bannerAlert,
  correspondenceInfo: state.correspondenceDetails.correspondenceInfo,
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  setTaskNotRelatedToAppealBanner,
  cancelTaskNotRelatedToAppeal,
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(
    CorrespondenceCancelTaskModal
  )
));
