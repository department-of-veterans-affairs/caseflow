import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect, useSelector } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { get } from 'lodash';

import { taskById } from '../selectors';
import { requestPatch } from '../uiReducer/uiActions';
import { taskActionData, currentDaysOnHold } from '../utils';
import TextareaField from '../../components/TextareaField';
import COPY from '../../../COPY';
import TASK_STATUSES from '../../../constants/TASK_STATUSES';
import QueueFlowModal from './QueueFlowModal';
import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';
import { setTaskNotRelatedToAppealBanner, cancelTaskNotRelatedToAppeal, organizationUsers } from '../correspondence/correspondenceDetailsReducer/correspondenceDetailsActions';
import Dropdown from '../../components/Dropdown';
import SearchableDropdown from '../../components/SearchableDropdown';
import AssignedCasesPage from '../AssignedCasesPage';

/* eslint-disable camelcase */
const CorrespondenceAssignTaskModal = (props) => {
  const userData = () => {
    const storeData = useSelector((state) => state.correspondenceDetails.correspondenceInfo.tasksUnrelatedToAppeal[0].usersInOrg);
    // console.log("following is store data output")
    // console.log(storeData)
    return storeData.map((reassignUsers) => {
      return {
        label: reassignUsers.css_id,
        value: reassignUsers.css_id
      }
    });
    // return storeData.map((orgUser) => {id: orgUser.css_id});
    // console.log(storeData);
  }
  // console.log("following is user data method output")
  const { task } = props;
  const taskData = taskActionData(props);

  // Show task instructions by default
  const shouldShowTaskInstructions = get(taskData, 'show_instructions', true);

  const [instructions, setInstructions] = useState('');
  const [instructionsAdded, setInstructionsAdded] = useState(true);
  const [assigneeAdded, setAssigneeAdded] = useState(false);
  // let assignee;

  // useEffect(() => {
  //   if () {
  //     setInstructionsAdded(false);
  //   } else {
  //     setInstructionsAdded(true);
  //   }
  // }, []);

  useEffect(() => {
    // Handle document search position
    if (instructions.length > 0) {
      setInstructionsAdded(false);
    } else {
      setInstructionsAdded(true);
    }
  }, [instructions]);

  const isVhaOffice = () => props.task.assignedTo.type === 'VhaRegionalOffice' ||
    props.task.assignedTo.type === 'VhaProgramOffice';

  const formatInstructions = () => {
    const reason_text = isVhaOffice() ?
      '##### REASON FOR RETURN:' :
      '##### REASON FOR CANCELLATION:';

    if (instructions.length > 0) {
      return `${reason_text}\n${instructions}`;
    }

    return instructions;
  };

  const validateForm = () => {
    if (!shouldShowTaskInstructions && assigneeAdded) {
      return true;
    }
    // if (instructions.length > 0 ) { console.log(assigneeAdded);}
    return (instructions.length > 0 && assigneeAdded);
  };

  const formChanged = () => {
    setAssigneeAdded(true);
  }
  // formChanged

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
      title= "Assign Task"
      button="Assign Task"
      submitDisabled= {!validateForm()}
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
          // multi
          dropdownStyling={{ position: 'relative', paddingBottom: '10px'}}
          creatable
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
  taskNotRelatedToAppealBanner: state.correspondenceDetails.bannerAlert,
  // organizationUsers: state.correspondenceDetails.showOrganizationUsers
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  setTaskNotRelatedToAppealBanner,
  cancelTaskNotRelatedToAppeal,
  // organizationUsers
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(
    CorrespondenceAssignTaskModal
  )
));
