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
import { setTaskNotRelatedToAppealBanner, cancelTaskNotRelatedToAppeal } from '../correspondence/correspondenceDetailsReducer/correspondenceDetailsActions';
import SearchableDropdown from '../../components/SearchableDropdown';

/* eslint-disable camelcase */
const CorrespondenceAssignTaskModal = (props) => {
  const userData = () => {
    const storeData = useSelector((state) => state.correspondenceDetails.correspondenceInfo.tasksUnrelatedToAppeal[0].reassignUsers[0]);
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

  const formChanged = () => {
    setAssigneeAdded(true);
  };

  const submit = () => {
    // const currentInstruction = (props.task.type === 'PostSendInitialNotificationLetterHoldingTask' ?
    //   `\nHold time: ${currentDaysOnHold(task)}/${task.onHoldDuration} days\n\n ${instructions}` : formatInstructions());

    // // eslint-disable-next-line no-debugger
    // debugger;
    // console.log(currentInstruction);

    const payload = {
      data: {
        task: {
          status: TASK_STATUSES.assigned,
          // assignedTo: assignee,
          instructions,
          ...(taskData?.business_payloads && { business_payloads: taskData?.business_payloads })
        }
      }
    };

    return props.assignTaskToUser(props.task_id, payload);

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
          dropdownStyling={{ position: 'relative', paddingBottom: '10px'}}
          options={userData()}
          placeholder="Select or search"
          // value={generateOptionsFromTags(doc.tags)}
          onChange={formChanged}
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
  taskNotRelatedToAppealBanner: state.correspondenceDetails.bannerAlert
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  setTaskNotRelatedToAppealBanner,
  cancelTaskNotRelatedToAppeal
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(
    CorrespondenceAssignTaskModal
  )
));
