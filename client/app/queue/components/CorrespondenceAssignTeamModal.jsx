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


  };

  // Additional properties - should be removed later once generic submit buttons are styled the same across all modals
  const modalProps = {};

  if ([
    'AssessDocumentationTask',
    'EducationAssessDocumentationTask',
    'HearingPostponementRequestMailTask'
  ].includes(task?.type) || task?.appeal?.hasCompletedSctAssignTask) {
    modalProps.submitButtonClassNames = ['usa-button'];
    modalProps.submitDisabled = !validateForm();
  }

  return (
    <QueueFlowModal
      {...modalProps}
      title="Assign Task"
      button="Assign Task"
      submitDisabled={!validateForm()}
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
      <SearchableDropdown
        name="User dropdown"
        label="Select a team"
        creatable
        placeholder="Select or search"
        styling={{ marginBottom: '20px' }}
        options={organizationOptions}
      />
      {shouldShowTaskInstructions &&
        <TextareaField
          name={taskData?.instructions_label ?? COPY.PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL}
          id="taskInstructions"
          onChange={(e) => setInstructions(e.target.value)}
          value={instructions}
        />
      }
    </QueueFlowModal>
  );
};
/* eslint-enable camelcase */

CorrespondenceAssignTeamModal.propTypes = {
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
  setShowActionsDropdown
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(
    CorrespondenceAssignTeamModal
  )
));
