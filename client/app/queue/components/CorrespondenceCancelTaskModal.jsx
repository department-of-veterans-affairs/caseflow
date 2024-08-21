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
  setShowActionsDropdown } from '../correspondence/correspondenceDetailsReducer/correspondenceDetailsActions';

/* eslint-disable camelcase */
const CorrespondenceCancelTaskModal = (props) => {
  const { task } = props;
  const taskData = taskActionData(props);

  // Show task instructions by default
  const shouldShowTaskInstructions = get(taskData, 'show_instructions', true);

  const [instructions, setInstructions] = useState('');
  const [instructionsAdded, setInstructionsAdded] = useState(true);

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

    // props.setShowActionsDropdown(false);

    return props.cancelTaskNotRelatedToAppeal(props.task_id, payload);

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
      title= "Cancel Task"
      button="Cancel Task"
      submitDisabled= {instructionsAdded}
      pathAfterSubmit={taskData?.redirect_after ?? `/queue/correspondence/${props.correspondence_uuid}`}
      submit={submit}
      validateForm={validateForm}
    >
      {taskData?.modal_body &&
        <React.Fragment>
          <div dangerouslySetInnerHTML={{ __html: taskData.modal_body }} />
          <br />
        </React.Fragment>
      }
      {shouldShowTaskInstructions &&
        <TextareaField
          name={taskData?.instructions_label ?? COPY.PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL}
          id="taskInstructions"
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
  setShowActionsDropdown: PropTypes.func,
  cancelTaskNotRelatedToAppeal: PropTypes.func,
  task: PropTypes.shape({
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
  showActionsDropdown: state.correspondenceDetails.showActionsDropdown,
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  setTaskNotRelatedToAppealBanner,
  cancelTaskNotRelatedToAppeal,
  setShowActionsDropdown
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(
    CorrespondenceCancelTaskModal
  )
));
