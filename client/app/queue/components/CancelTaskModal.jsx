import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { get } from 'lodash';

import { taskById } from '../selectors';
import { requestPatch } from '../uiReducer/uiActions';
import { taskActionData, currentDaysOnHold } from '../utils';
import TextareaField from '../../components/TextareaField';
import COPY from '../../../COPY';
import TASK_STATUSES from '../../../constants/TASK_STATUSES';
import QueueFlowModal from './QueueFlowModal';

/* eslint-disable camelcase */
const CancelTaskModal = (props) => {
  const { task, hearingDay, highlightFormItems } = props;
  const taskData = taskActionData(props);

  // Show task instructions by default
  const shouldShowTaskInstructions = get(taskData, 'show_instructions', true);

  const [instructions, setInstructions] = useState('');

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
    if (!shouldShowTaskInstructions) {
      return true;
    }

    return instructions.length > 0;
  };

  const submit = () => {
    const currentInstruction = (props.task.type === 'PostSendInitialNotificationLetterHoldingTask' ?
      `\nHold time: ${currentDaysOnHold(task)}/${task.onHoldDuration} days\n\n ${instructions}` : formatInstructions());
    const payload = {
      data: {
        task: {
          status: TASK_STATUSES.cancelled,
          instructions: currentInstruction,
          ...(taskData?.business_payloads && { business_payloads: taskData?.business_payloads })
        }
      }
    };

    const hearingScheduleLink = taskData?.back_to_hearing_schedule ?
      <p>
        <Link href={`/hearings/schedule/assign?regional_office_key=${hearingDay.regionalOffice}`}>
          Back to Hearing Schedule
        </Link>
      </p> : null;
    const successMsg = {
      title: taskData?.message_title ?? 'Task was cancelled successfully.',
      detail: (
        <span>
          <span dangerouslySetInnerHTML={{ __html: taskData.message_detail }} />
          {hearingScheduleLink}
        </span>
      )
    };

    return props.requestPatch(`/tasks/${task.taskId}`, payload, successMsg);
  };

  // Additional properties - should be removed later once generic submit buttons are styled the same across all modals
  const modalProps = {};

  if ([
    'AssessDocumentationTask',
    'EducationAssessDocumentationTask',
    'HearingPostponementRequestMailTask'
  ].includes(task?.type)) {
    modalProps.submitButtonClassNames = ['usa-button'];
    modalProps.submitDisabled = !validateForm();
  }

  if (props.task.type === 'SendInitialNotificationLetterTask' ||
    props.task.type === 'PostSendInitialNotificationLetterHoldingTask' ||
    props.task.type === 'SendFinalNotificationLetterTask') {
    return (
      <QueueFlowModal
        title={taskData?.modal_title ?? ''}
        button={taskData?.modal_button_text ?? COPY.MODAL_SUBMIT_CANCEL_BUTTON_CONTESTED_CLAIM}
        pathAfterSubmit={taskData?.redirect_after ?? '/queue'}
        submit={submit}
        validateForm={validateForm}
        submitButtonClassNames={['usa-button']}
        submitDisabled={!(instructions.length)}
      >
        {taskData?.modal_body &&
          <React.Fragment>
            <div dangerouslySetInnerHTML={{ __html: taskData.modal_body }} />
            <br />
          </React.Fragment>
        }
        {get(taskData, 'show_instructions', true) &&
          <TextareaField
            name={COPY.ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL}
            // errorMessage={highlightFormItems && instructions.length === 0 ?
            //   COPY.INSTRUCTIONS_ERROR_FIELD_REQUIRED : null}
            id="taskInstructions"
            onChange={setInstructions}
            placeholder="This is a description of instuctions and context for this action."
            value={instructions}
          />
        }
      </QueueFlowModal>
    );
  }

  return (
    <QueueFlowModal
      {...modalProps}
      title={taskData?.modal_title ?? ''}
      button={taskData?.modal_button_text ?? COPY.MODAL_SUBMIT_BUTTON}
      pathAfterSubmit={taskData?.redirect_after ?? '/queue'}
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
          name={taskData?.instructions_label ?? COPY.ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL}
          errorMessage={highlightFormItems && instructions.length === 0 ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
          id="taskInstructions"
          onChange={setInstructions}
          value={instructions}
        />
      }
    </QueueFlowModal>
  );

};
/* eslint-enable camelcase */

CancelTaskModal.propTypes = {
  hearingDay: PropTypes.shape({
    regionalOffice: PropTypes.string
  }),
  requestPatch: PropTypes.func,
  task: PropTypes.shape({
    assignedTo: PropTypes.shape({
      type: PropTypes.string
    }),
    taskId: PropTypes.string,
    type: PropTypes.string,
    onHoldDuration: PropTypes.number
  }),
  highlightFormItems: PropTypes.bool
};

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  hearingDay: state.ui.hearingDay,
  highlightFormItems: state.ui.highlightFormItems
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(
    CancelTaskModal
  )
));
