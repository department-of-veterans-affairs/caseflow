import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { sprintf } from 'sprintf-js';

import TASK_STATUSES from '../../../constants/TASK_STATUSES';
import TASK_ACTIONS from '../../../constants/TASK_ACTIONS';
import HEARING_DISPOSITION_TYPES from '../../../constants/HEARING_DISPOSITION_TYPES';
import COPY from '../../../COPY';

import TextareaField from '../../components/TextareaField';
import RadioField from '../../components/RadioField';
import { maxWidthFormInput } from './details/style';
import FlowModal from '../../components/FlowModal';
import { appellantFullName, taskPayload } from '../utils';
import ApiUtil from '../../util/ApiUtil';
import { onReceiveAlerts } from '../../components/common/actions';
import { useDispatch } from 'react-redux';

const ACTIONS = {
  RESCHEDULE: 'reschedule',
  SCHEDULE_LATER: 'schedule_later'
};

const AFTER_DISPOSITION_UPDATE_ACTION_OPTIONS = [
  {
    displayText: COPY.RESCHEDULE_IMMEDIATELY_DISPLAY_TEXT,
    value: ACTIONS.RESCHEDULE,
  },
  {
    displayText: COPY.SCHEDULE_LATER_DISPLAY_TEXT,
    value: ACTIONS.SCHEDULE_LATER,
  }
];

export const ScheduledInErrorModal = ({ update, cancelHandler, hearing, saveHearing }) => {
  const { notes, appealExternalId, hearingDispositionTaskId, externalId } = hearing;

  const [afterDispositionUpdateAction, setAfterDispositionUpdateAction] = useState('');
  const disposition = HEARING_DISPOSITION_TYPES.scheduled_in_error;
  const dispatch = useDispatch();

  const scheduleLaterSuccessMessage = {
    type: 'success',
    title: sprintf(COPY.SCHEDULE_LATER_SUCCESS_MESSAGE, appellantFullName(hearing))
  };

  const resetSaveState = () => {
    if (afterDispositionUpdateAction === ACTIONS.RESCHEDULE) {
      // Construct the URL to redirect
      const baseUrl = `${window.location.origin}/queue/appeals`;
      const taskUrl = `${baseUrl}/${appealExternalId}/tasks/${hearingDispositionTaskId}`;
      const params = `?action=${ACTIONS.RESCHEDULE}&disposition=${disposition}`;

      // Redirect to the Queue App
      window.location.href = `${taskUrl}/${TASK_ACTIONS.SCHEDULE_VETERAN_V2_PAGE.value}${params}`;
    } else {
      cancelHandler();
    }
  };

  const submit = async () => {
    // Send the event to google analytics
    window.analyticsEvent('Hearings', disposition, afterDispositionUpdateAction);

    // Determine whether to redirect to the ful page schedule veteran flow
    if (afterDispositionUpdateAction === ACTIONS.RESCHEDULE) {
      // Add the notes to the task before continuing
      await saveHearing(externalId, { notes });

      // This is a failed Promise to prevent `QueueFlowModal` from thinking the
      // request completed successfully, and redirecting back to the `CaseDetails` page.
      return Promise.resolve();
    } else if (afterDispositionUpdateAction === ACTIONS.SCHEDULE_LATER) {
      // Construct the payload for cancelling the scheduled hearing task
      const task = { status: TASK_STATUSES.cancelled };
      const hearingDetails = {
        disposition,
        after_disposition_update: { action: ACTIONS.SCHEDULE_LATER },
        hearing_notes: notes
      };

      // Update the task status to cancelled
      await ApiUtil.patch(`/tasks/${hearingDispositionTaskId}`, taskPayload(hearingDetails, task));

      // Add the notes to the hearing before continuing
      update({ notes, disposition });

      // Receive the alert after cancelling the hearing
      dispatch(onReceiveAlerts([scheduleLaterSuccessMessage]));
    }
  };

  return (
    <FlowModal
      saveSuccessful={false}
      resetSaveState={resetSaveState}
      title={COPY.HEARING_SCHEDULED_IN_ERROR_MODAL_TITLE}
      submit={submit}
      validateForm={() => true}
      onCancel={cancelHandler}
    >
      <p> {COPY.HEARING_SCHEDULED_IN_ERROR_MODAL_INTRO} </p>
      <RadioField
        name="postponeAfterDispositionUpdateAction"
        hideLabel
        strongLabel
        options={AFTER_DISPOSITION_UPDATE_ACTION_OPTIONS}
        onChange={(option) => setAfterDispositionUpdateAction(option)}
        value={afterDispositionUpdateAction}
      />
      <TextareaField
        id="scheduled-in-error-notes"
        name="Notes"
        strongLabel
        styling={maxWidthFormInput}
        value={hearing?.notes}
        onChange={(updatedNotes) => update({ notes: updatedNotes })}
        maxlength={1000}
      />
    </FlowModal>
  );
};

ScheduledInErrorModal.propTypes = {
  saveHearing: PropTypes.func,
  notes: PropTypes.string,
  appealExternalId: PropTypes.string,
  hearingDispositionTaskId: PropTypes.string,
  scheduledHearing: PropTypes.object,
  cancelHandler: PropTypes.func,
  hearing: PropTypes.object,
  history: PropTypes.object,
  update: PropTypes.func,
};
