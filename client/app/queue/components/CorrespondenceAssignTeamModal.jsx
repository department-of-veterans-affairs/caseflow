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
  cancelTaskNotRelatedToAppeal
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
    if (shouldShowTaskInstructions) {
      return instructionsAdded && teamAssignedFlag;
    }

    return teamAssignedFlag;
  };

  const formChanged = (organization) => {
    setTeamAssignedFlag(organization);
  };

  const updateCorrespondence = () => {
    const updatedCorrespondence = { ...props.correspondenceInfo };
    const assignedTeam = teamAssignedFlag?.label || '';
    const taskUpdate = updatedCorrespondence.tasksUnrelatedToAppeal.find(
      (task) => task.uniqueId === parseInt(props.task_id, 10)
    );

    if (taskUpdate) {
      const previousOrg = taskUpdate.assignedTo;
      const previousOrgValue = taskUpdate.assignedToValue;

      // Update the assigned organization
      taskUpdate.assignedTo = assignedTeam;
      taskUpdate.instructions.push(instructions);

      // remove available actions if the user isn't part of the org
      if (!props?.userOrganizations?.includes(assignedTeam)) {
        taskUpdate.availableActions = [];
      }

      // Remove the newly assigned organization from the list
      taskUpdate.organizations = taskUpdate.organizations.filter(
        (org) => org.label !== teamAssignedFlag?.label
      );

      // Add the previous organization back to the list, if it exists
      if (previousOrg && previousOrg !== teamAssignedFlag?.label) {
        taskUpdate.organizations.push({
          label: previousOrg,
          value: previousOrgValue,
        });
      }

      // Reset the selected organization to show placeholder text
      setTeamAssignedFlag(null);
    }

    return updatedCorrespondence;
  };

  const submit = () => {
    if (teamAssignedFlag && typeof teamAssignedFlag === 'object') {
      const correspondence = updateCorrespondence();
      const payload = {
        data: {
          assigned_to: teamAssignedFlag.label,
          instructions,
          ...(taskData?.business_payloads && { business_payloads: taskData.business_payloads })
        }
      };

      const frontendParams = {
        taskId: props.task_id,
        taskName: taskList.label,
        teamName: teamAssignedFlag.label
      };

      return props.assignTaskToTeam(payload, frontendParams, correspondence);
    }
    console.error('No valid organization selected');

  };

  const modalProps = {
    submitButtonClassNames: ['usa-button'],
    submitDisabled: !validateForm()
  };

  return (
    <QueueFlowModal
      {...modalProps}
      title="Assign task"
      button="Assign task"
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
          name={taskData?.instructions_label ?? COPY.PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL}
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
  cancelTaskNotRelatedToAppeal: PropTypes.func,
  assignTaskToTeam: PropTypes.func.isRequired,
  task: PropTypes.shape({
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
  assignTaskToTeam
}, dispatch);

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(CorrespondenceAssignTeamModal)
);
