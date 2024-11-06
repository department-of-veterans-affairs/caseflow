import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect, useSelector } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { get } from 'lodash';

import { taskById } from '../selectors';
import { requestPatch } from '../uiReducer/uiActions';
import { taskActionData } from '../utils';
import TextareaField from '../../components/TextareaField';
import COPY from '../../../COPY';
import QueueFlowModal from './QueueFlowModal';
import {
  setTaskNotRelatedToAppealBanner,
  assignTaskToUser
} from '../correspondence/correspondenceDetailsReducer/correspondenceDetailsActions';
import SearchableDropdown from '../../components/SearchableDropdown';

/* eslint-disable camelcase */
const CorrespondenceAssignTaskModal = (props) => {
  const userData = () => {
    const storeData = useSelector((state) =>
      state.correspondenceDetails.correspondenceInfo.tasksUnrelatedToAppeal.find(
        (task) => parseInt(task.uniqueId, 10) === parseInt(props.task_id, 10)
      ).reassignUsers
    );

    return storeData.map((userIteration) => {
      return {
        label: userIteration,
        value: userIteration
      };
    });
  };

  const taskData = taskActionData(props);

  // Show task instructions by default
  const shouldShowTaskInstructions = get(taskData, 'show_instructions', true);

  const [instructions, setInstructions] = useState('');
  const [instructionsAdded, setInstructionsAdded] = useState(false);
  const [assigneeAdded, setAssigneeAdded] = useState(false);
  const [assignee, setAssignee] = useState('');

  const currentTask = props.correspondenceInfo.tasksUnrelatedToAppeal.find(
    (task) => parseInt(props.task_id, 10) === parseInt(task.uniqueId, 10)
  );

  useEffect(() => {
    // Handle the instructions boolean for submit button clickability
    if (instructions.length > 0) {
      setInstructionsAdded(true);
    } else {
      setInstructionsAdded(false);
    }
  }, [instructions]);

  const validateForm = () => {
    if (!shouldShowTaskInstructions && assigneeAdded) {
      return true;
    }

    return (instructionsAdded && assigneeAdded);
  };

  const formChanged = (user) => {
    setAssigneeAdded(true);
    setAssignee(user?.value);
  };

  const setActions = (assignedUser) => {
    if (props.userCssId === assignedUser) {
      return currentTask?.availableActions;
    }

    return [];
  };

  const updateCorrespondence = () => {
    const tempCor = props.correspondenceInfo;

    tempCor.tasksUnrelatedToAppeal.find(
      (task) => task.uniqueId === parseInt(props.task_id, 10)
    ).assignedTo = assignee;
    tempCor.tasksUnrelatedToAppeal.find(
      (task) => task.uniqueId === parseInt(props.task_id, 10)
    ).instructions.push(instructions);
    tempCor.tasksUnrelatedToAppeal.find(
      (task) => task.uniqueId === parseInt(props.task_id, 10)
    ).availableActions = setActions(assignee);

    return tempCor;
  };

  const submit = () => {
    const correspondence = updateCorrespondence();
    const updatedTask = correspondence.tasksUnrelatedToAppeal.find(
      (task) => parseInt(props.task_id, 10) === parseInt(task.uniqueId, 10)
    );

    const payload = {
      data: {
        assigned_to: assignee,
        instructions,
        ...(taskData?.business_payloads && { business_payloads: taskData?.business_payloads })
      }
    };

    const frontendParams = {
      taskId: props.task_id,
      taskName: updatedTask.label,
      assignedName: updatedTask.assignedTo
    };

    return props.assignTaskToUser(props.task_id, payload, frontendParams, correspondence);
  };

  return (
    <QueueFlowModal
      title= {currentTask?.assignedToOrg ? 'Assign task' : 'Re-assign to person'}
      button="Assign task"
      submitDisabled= {!validateForm()}
      submitButtonClassNames= "usa-button"
      pathAfterSubmit={
        taskData?.redirect_after ?? `/queue/correspondence/${props.correspondence_uuid}`
      }
      submit={submit}
      validateForm={validateForm}
    >
      {taskData?.modal_body &&
        <React.Fragment>
          <div dangerouslySetInnerHTML={{ __html: taskData.modal_body }} />
          <br />
        </React.Fragment>
      }
      {
        <SearchableDropdown
          name="User dropdown"
          label="Select a user"
          dropdownStyling={{ position: 'relative' }}
          options={userData()}
          placeholder="Select or search"
          onChange={(value) => formChanged(value)}
          styling={{ marginBottom: '20px' }}
        />
      }
      {shouldShowTaskInstructions &&
        <TextareaField
          name={
            taskData?.instructions_label ?? COPY.CORRESPONDENCE_CASES_ASSIGN_TO_PERSON_MODAL_INSTRUCTIONS_TITLE
          }
          id="taskInstructions"
          onChange={setInstructions}
          value={instructions}
        />
      }
    </QueueFlowModal>
  );

};
/* eslint-enable camelcase */

CorrespondenceAssignTaskModal.propTypes = {
  requestPatch: PropTypes.func,
  correspondenceInfo: PropTypes.object,
  correspondence_uuid: PropTypes.string,
  task_id: PropTypes.string,
  assignTaskToUser: PropTypes.func,
  userCssId: PropTypes.string,
  currentTask: PropTypes.shape({
    appeal: PropTypes.shape({
      hasCompletedSctAssignTask: PropTypes.bool
    }),
    assignedTo: PropTypes.shape({
      type: PropTypes.string
    }),
    taskId: PropTypes.string,
    type: PropTypes.string,
    onHoldDuration: PropTypes.number
  })
};

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.task_id }),
  taskNotRelatedToAppealBanner: state.correspondenceDetails.bannerAlert,
  correspondenceInfo: state.correspondenceDetails.correspondenceInfo
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  setTaskNotRelatedToAppealBanner,
  assignTaskToUser
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(
    CorrespondenceAssignTaskModal
  )
));
