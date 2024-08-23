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
import TASK_STATUSES from '../../../constants/TASK_STATUSES';
import QueueFlowModal from './QueueFlowModal';
import { setTaskNotRelatedToAppealBanner, assignTaskToUser } from '../correspondence/correspondenceDetailsReducer/correspondenceDetailsActions';
import SearchableDropdown from '../../components/SearchableDropdown';

/* eslint-disable camelcase */
const CorrespondenceAssignTaskModal = (props) => {
  const userData = () => {
    const storeData = useSelector((state) =>
      state.correspondenceDetails.correspondenceInfo.tasksUnrelatedToAppeal.find((task) => parseInt(task.uniqueId, 10) ===
                                                                                  parseInt(props.task_id, 10)).reassignUsers[0]
    );

    return storeData.map((userIteration) => {
      return {
        label: userIteration,
        value: userIteration
      };
    });
  };

  const { task } = props;
  const taskData = taskActionData(props);

  // Show task instructions by default
  const shouldShowTaskInstructions = get(taskData, 'show_instructions', true);

  const [instructions, setInstructions] = useState('');
  const [instructionsAdded, setInstructionsAdded] = useState(false);
  const [assigneeAdded, setAssigneeAdded] = useState(false);
  const [assignee, setAssignee] = useState("");

  useEffect(() => {
    // Handle document search position
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

  // const getDate = () => {
  //   const date = new Date();

  //   let day = date.getDate();
  //   let month = date.getMonth() + 1;
  //   let year = date.getFullYear();

  //   // This arrangement can be altered based on how we want the date's format to appear.
  //   let currentDate = `${month}/${day}/${year}`;

  //   return currentDate;
  // }

  const updateCorrespondence = () => {
    let tempCor = props.correspondenceInfo;
    tempCor.tasksUnrelatedToAppeal.find((task) => task.uniqueId == props.task_id).assignedTo = assignee;
    // tempCor.tasksUnrelatedToAppeal.find((task) => task.uniqueId == props.task_id).assigned_to_type = "User";
    // tempCor.tasksUnrelatedToAppeal.find((task) => task.uniqueId  == props.task_id).assignedOn = getDate();
    tempCor.tasksUnrelatedToAppeal.find((task) => task.uniqueId  == props.task_id).instructions = instructions;

    return tempCor;
  }

  const submit = () => {
    // const currentInstruction = (props.task.type === 'PostSendInitialNotificationLetterHoldingTask' ?
    //   `\nHold time: ${currentDaysOnHold(task)}/${task.onHoldDuration} days\n\n ${instructions}` : formatInstructions());

    // // eslint-disable-next-line no-debugger
    // debugger;
    // console.log(currentInstruction);

    const payload = {
      data: {
        // status: TASK_STATUSES.assigned,
        assigned_to: assignee,
        // assigned_at: getDate(),
        instructions: instructions,
        // type: "User",
        ...(taskData?.business_payloads && { business_payloads: taskData?.business_payloads })
      }
    };
    // debugger;
    return props.assignTaskToUser(props.task_id, updateCorrespondence, payload);
  };

  return (
    <QueueFlowModal
      title= "Assign Task"
      button="Assign Task"
      submitDisabled= {!validateForm()}
      submitButtonClassNames= {'usa-button'}
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
      {
        <SearchableDropdown
          // key={doc.id}
          name="User dropdown"
          label="Select a user"
          dropdownStyling={{ position: 'relative' }}
          options={userData()}
          placeholder="Select or search"
          // value={generateOptionsFromTags(doc.tags)}
          // onChange={formChanged(value)}
          onChange={(value) => formChanged(value)}
          styling={{ marginBottom: '20px' }}
        />
      }
      {shouldShowTaskInstructions &&
        <TextareaField
          // name={taskData?.instructions_label ?? COPY.PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL}
          name={taskData?.instructions_label ?? COPY.CORRESPONDENCE_CASES_ASSIGN_TASK_MODAL_INSTRUCTIONS_TITLE}
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
};

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
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
