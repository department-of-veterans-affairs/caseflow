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
import QueueFlowModal from './QueueFlowModal';
import {
  setTaskNotRelatedToAppealBanner,
  assignTaskToTeam,
  cancelTaskNotRelatedToAppeal,
  setShowActionsDropdown
} from '../correspondence/correspondenceDetailsReducer/correspondenceDetailsActions';
import SearchableDropdown from '../../components/SearchableDropdown';

/* eslint-disable camelcase */
const CorrespondenceAssignTeamModal = (props) => {
  const { task_id, correspondenceInfo } = props;

  const taskList = correspondenceInfo?.tasksUnrelatedToAppeal?.find(
    (task) => parseInt(task.uniqueId, 10) === parseInt(task_id, 10)
  );

  const organizations = taskList?.organizations || [];
  const organizationOptions = organizations.map((org) => ({
    label: org.label,
    value: org.value
  }));

  const taskData = taskActionData(props);

  // Show task instructions by default
  const shouldShowTaskInstructions = get(taskData, 'show_instructions', true);

  const [instructions, setInstructions] = useState('');
  const [instructionsAdded, setInstructionsAdded] = useState(false);
  const [teamAssignedFlag, setTeamAssignedFlag] = useState(null);

  useEffect(() => {
    setInstructionsAdded(instructions.length > 0);
  }, [instructions]);

  const validateForm = () => {
    return !shouldShowTaskInstructions ? teamAssignedFlag : (instructionsAdded && teamAssignedFlag);
  };

  const formChanged = (organization) => {
    setTeamAssignedFlag(organization);
  };

  const updateCorrespondence = () => {
    const updatedCorrespondence = { ...props.correspondenceInfo };
    const task = updatedCorrespondence.tasksUnrelatedToAppeal.find(
      (task) => task.uniqueId === parseInt(props.task_id, 10)
    );

    if (task) {
      const previousOrg = task.assignedTo; // Get the current assigned organization
      const previousOrgValue = task.assignedToValue; // Get the current assigned organization value

      // Update the assigned organization
      task.assignedTo = teamAssignedFlag?.label || ''; // Use teamAssignedFlag.label
      task.instructions.push(instructions);

      // Remove the newly assigned organization from the list
      task.organizations = task.organizations.filter(
        (org) => org.label !== teamAssignedFlag?.label
      );

      // Add the previous organization back to the list, if it exists
      if (previousOrg && previousOrg !== teamAssignedFlag?.label) {
        task.organizations.push({
          label: previousOrg,
          value: previousOrgValue,
        });
      }

      // Reset the selected organization to show placeholder text
      setTeamAssignedFlag(null); // Reset the selected organization
    }

    return updatedCorrespondence;
  };

  const submit = () => {
    if (teamAssignedFlag && typeof teamAssignedFlag === 'object') {
      const correspondence = updateCorrespondence();
      const payload = {
        data: {
          assigned_to: teamAssignedFlag.label,
          instructions: instructions,
          ...(taskData?.business_payloads && { business_payloads: taskData.business_payloads })
        }
      };

      const frontendParams = {
        taskId: props.task_id,
        teamName: teamAssignedFlag.label
      };

      return props.assignTaskToTeam(payload, frontendParams, correspondence);
    } else {
      console.error('No valid organization selected');
    }
  };

  const modalProps = {
    submitButtonClassNames: ['usa-button'],
    submitDisabled: !validateForm()
  };

  return (
    <QueueFlowModal
      {...modalProps}
      title="Assign Task"
      button="Assign Task"
      pathAfterSubmit={taskData?.redirect_after ?? `/queue/correspondence/${props.correspondence_uuid}`}
      submit={submit}
      validateForm={validateForm}
    >
      {taskData?.modal_body && (
        <>
          <div dangerouslySetInnerHTML={{ __html: taskData.modal_body }} />
          <br />
        </>
      )}
      <SearchableDropdown
        name="Organization dropdown"
        label="Select a team"
        dropdownStyling={{ position: 'relative' }}
        placeholder="Select or search"
        styling={{ marginBottom: '20px' }}
        options={organizationOptions}
        value={teamAssignedFlag}
        onChange={formChanged}
      />
      {shouldShowTaskInstructions && (
        <TextareaField
          name={taskData?.instructions_label ?? COPY.CORRESPONDENCE_CASES_ASSIGN_TASK_MODAL_INSTRUCTIONS_TITLE}
          id="taskInstructions"
          onChange={setInstructions}
          value={instructions}
        />
      )}
    </QueueFlowModal>
  );
};
/* eslint-enable camelcase */

CorrespondenceAssignTeamModal.propTypes = {
  requestPatch: PropTypes.func,
  setShowActionsDropdown: PropTypes.func,
  cancelTaskNotRelatedToAppeal: PropTypes.func,
  assignTaskToTeam: PropTypes.func.isRequired,
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
  task_id: PropTypes.string.isRequired,
  correspondence_uuid: PropTypes.string.isRequired,
  correspondenceInfo: PropTypes.shape({
    tasksUnrelatedToAppeal: PropTypes.arrayOf(PropTypes.shape({
      uniqueId: PropTypes.number,
      organizations: PropTypes.arrayOf(PropTypes.shape({
        label: PropTypes.string,
        value: PropTypes.number
      }))
    }))
  })
};

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.task_id }),
  taskNotRelatedToAppealBanner: state.correspondenceDetails.bannerAlert,
  correspondenceInfo: state.correspondenceDetails.correspondenceInfo,
  showActionsDropdown: state.correspondenceDetails.showActionsDropdown,
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  setTaskNotRelatedToAppealBanner,
  cancelTaskNotRelatedToAppeal,
  setShowActionsDropdown,
  assignTaskToTeam
}, dispatch);

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(CorrespondenceAssignTeamModal)
);
