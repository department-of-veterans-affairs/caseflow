import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { find } from 'lodash';
import { sprintf } from 'sprintf-js';

import TASK_STATUSES from '../../../constants/TASK_STATUSES';
import TASK_ACTIONS from '../../../constants/TASK_ACTIONS';
import HEARING_DISPOSITION_TYPES from '../../../constants/HEARING_DISPOSITION_TYPES';
import COPY from '../../../COPY';

import TextareaField from '../../components/TextareaField';
import RadioField from '../../components/RadioField';
import { maxWidthFormInput } from '../../hearings/components/details/style';
import FlowModal from '../../components/FlowModal';

import { taskById, appealWithDetailSelector } from '../selectors';
import { onReceiveAmaTasks } from '../QueueActions';
import { requestPatch, showErrorMessage } from '../uiReducer/uiActions';
import { setScheduledHearing } from '../../components/common/actions';

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

const HearingScheduledInErrorModal = (props) => {
  const {
    appeal, task, scheduledHearing
  } = props;

  const [afterDispositionUpdateAction, setAfterDispositionUpdateAction] = useState('');
  const [isPosting, setIsPosting] = useState(false);

  const hearing = find(appeal.hearings, { externalId: task.externalHearingId });

  useEffect(() => {
    props.setScheduledHearing({ notes: hearing?.notes });
  }, []);

  const scheduleLaterPayload = {
    data: {
      task: {
        status: TASK_STATUSES.cancelled,
        business_payloads: {
          values: {
            disposition: HEARING_DISPOSITION_TYPES.scheduled_in_error,
            after_disposition_update: { action: ACTIONS.SCHEDULE_LATER },
            hearing_notes: scheduledHearing?.notes
          },
        },
      },
    },
  };

  const scheduleLaterSuccessMessage = {
    title: sprintf(COPY.SCHEDULE_LATER_SUCCESS_MESSAGE, appeal?.veteranFullName)
  };

  const resetSaveState = () => {
    if (afterDispositionUpdateAction === ACTIONS.RESCHEDULE) {
      props.history.push(
        `/queue/appeals/${appeal.externalId}/tasks/${task.taskId}/${TASK_ACTIONS.SCHEDULE_VETERAN_V2_PAGE.value}`
      );
    }
  };

  const submit = () => {
    // Send the event to google analytics
    window.analyticsEvent('Hearings', HEARING_DISPOSITION_TYPES.scheduled_in_error, afterDispositionUpdateAction);

    // Determine whether to redirect to the ful page schedule veteran flow
    if (afterDispositionUpdateAction === ACTIONS.RESCHEDULE) {
      // Change the disposition in the store
      props.setScheduledHearing({
        action: ACTIONS.RESCHEDULE,
        taskId: task.taskId,
        disposition: HEARING_DISPOSITION_TYPES.scheduled_in_error
      });

      // This is a failed Promise to prevent `QueueFlowModal` from thinking the
      // request completed successfully, and redirecting back to the `CaseDetails` page.
      return Promise.resolve();
    } else if (afterDispositionUpdateAction === ACTIONS.SCHEDULE_LATER) {
      if (isPosting) {
        return;
      }

      setIsPosting(true);

      return props.
        requestPatch(`/tasks/${task.taskId}`, scheduleLaterPayload, scheduleLaterSuccessMessage).
        then(
          (resp) => {
            setIsPosting(false);
            props.onReceiveAmaTasks(resp.body.tasks.data);
          },
          () => {
            setIsPosting(false);

            props.showErrorMessage({
              title: COPY.REMOVE_HEARING_ERROR_TITLE,
              detail: COPY.REMOVE_HEARING_ERROR_DETAIL,
            });
          }
        );
    }
  };

  return (
    <FlowModal
      history={props.history}
      title={COPY.HEARING_SCHEDULED_IN_ERROR_MODAL_TITLE}
      submit={submit}
      validateForm={() => true}
      resetSaveState={resetSaveState}
      pathAfterSubmit={`/queue/appeals/${appeal.externalId}`}
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
        name="Notes"
        strongLabel
        styling={maxWidthFormInput}
        value={scheduledHearing?.notes}
        onChange={(notes) => props.setScheduledHearing({ notes })}
        maxlength={1000}
      />
    </FlowModal>
  );
};

HearingScheduledInErrorModal.propTypes = {
  scheduledHearing: PropTypes.object,
  setScheduledHearing: PropTypes.func,
  appeal: PropTypes.shape({
    externalId: PropTypes.string,
    veteranFullName: PropTypes.string,
    hearings: PropTypes.array
  }),
  onReceiveAmaTasks: PropTypes.func,
  flowModal: PropTypes.elementType,
  history: PropTypes.object,
  requestPatch: PropTypes.func,
  showErrorMessage: PropTypes.func,
  task: PropTypes.shape({
    taskId: PropTypes.string,
    externalHearingId: PropTypes.string
  })
};

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  appeal: appealWithDetailSelector(state, ownProps),
  scheduledHearing: state.components.scheduledHearing,
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      setScheduledHearing,
      requestPatch,
      onReceiveAmaTasks,
      showErrorMessage
    },
    dispatch
  );

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(HearingScheduledInErrorModal)
);
