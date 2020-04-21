import React, { useContext, useState } from 'react';
import PropTypes from 'prop-types';
import { formatDateStr } from '../../util/DateUtil';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';

import {
  taskById,
  appealWithDetailSelector
} from '../selectors';
import { onReceiveAmaTasks, onReceiveAppealDetails } from '../QueueActions';
import {
  requestPatch, showErrorMessage
} from '../uiReducer/uiActions';
import QueueFlowModal from './QueueFlowModal';
import { taskActionData } from '../utils';
import TASK_STATUSES from '../../../constants/TASK_STATUSES';

import RadioField from '../../components/RadioField';
import AssignHearingForm from '../../hearings/components/modalForms/AssignHearingForm';
import ScheduleHearingLaterWithAdminActionForm from
  '../../hearings/components/modalForms/ScheduleHearingLaterWithAdminActionForm';

import { HearingsFormContext } from '../../hearings/contexts/HearingsFormContext';

const ACTIONS = {
  RESCHEDULE: 'reschedule',
  SCHEDULE_LATER: 'schedule_later',
  SCHEDULE_LATER_WITH_ADMIN_ACTION: 'schedule_later_with_admin_action'
};

const AFTER_DISPOSITION_UPDATE_ACTION_OPTIONS = [
  {
    displayText: 'Reschedule immediately',
    value: ACTIONS.RESCHEDULE
  },
  {
    displayText: 'Send to Schedule Veteran list',
    value: ACTIONS.SCHEDULE_LATER
  },
  {
    displayText: 'Apply admin action',
    value: ACTIONS.SCHEDULE_LATER_WITH_ADMIN_ACTION
  }
];

const PostponeHearingModal = (props) => {
  const [afterDispositionUpdateAction, setAfterDispositionUpdateAction] = useState('');
  const [showErrorMessages, setShowErrorMessages] = useState(false);
  const [isPosting, setIsPosting] = useState(false);

  const { appeal, task } = props;
  const taskData = taskActionData(props);

  const hearingsFormContext = useContext(HearingsFormContext);
  const assignHearingForm = hearingsFormContext.state.hearingForms?.assignHearingForm || {};
  const scheduleHearingLaterWithAdminActionForm =
    hearingsFormContext.state.hearingForms?.scheduleHearingLaterWithAdminActionForm || {};

  const validateRescheduleValues = () => {
    const { errorMessages: { hasErrorMessages } } = assignHearingForm;

    setShowErrorMessages({ hasErrorMessages });

    return !hasErrorMessages;
  };

  const validateScheduleLaterValues = () => {
    const { errorMessages: { hasErrorMessages } } = scheduleHearingLaterWithAdminActionForm;

    setShowErrorMessages(hasErrorMessages);

    return !hasErrorMessages;
  };

  const validateForm = () => {
    if (afterDispositionUpdateAction === ACTIONS.RESCHEDULE) {
      return validateRescheduleValues();
    } else if (afterDispositionUpdateAction === ACTIONS.SCHEDULE_LATER_WITH_ADMIN_ACTION) {
      return validateScheduleLaterValues();
    }

    return true;
  };

  const getReschedulePayload = () => {
    const {
      // eslint-disable-next-line camelcase
      apiFormattedValues: { scheduled_time_string, hearing_day_id, hearing_location }
    } = assignHearingForm;

    return {
      action: ACTIONS.RESCHEDULE,
      new_hearing_attrs: {
        scheduled_time_string,
        hearing_day_id,
        hearing_location
      }
    };
  };

  const getSuccessMsg = () => {
    const { hearingDay } = assignHearingForm || {};

    if (afterDispositionUpdateAction === ACTIONS.RESCHEDULE) {
      const hearingDateStr = formatDateStr(hearingDay.hearingDate, 'YYYY-MM-DD', 'MM/DD/YYYY');
      const title = `You have successfully assigned ${appeal.veteranFullName} ` +
                    `to a hearing on ${hearingDateStr}.`;

      return { title };
    }

    return {
      title: `${appeal.veteranFullName} was successfully added back to the schedule veteran list.`
    };
  };

  const getScheduleLaterPayload = () => {
    if (afterDispositionUpdateAction === ACTIONS.SCHEDULE_LATER_WITH_ADMIN_ACTION) {
      const {
        // eslint-disable-next-line camelcase
        apiFormattedValues: { with_admin_action_klass, admin_action_instructions }
      } = scheduleHearingLaterWithAdminActionForm;

      return {
        action: ACTIONS.SCHEDULE_LATER,
        with_admin_action_klass,
        admin_action_instructions
      };
    }

    return {
      action: ACTIONS.SCHEDULE_LATER
    };
  };

  const getPayload = () => {
    return {
      data: {
        task: {
          status: TASK_STATUSES.cancelled,
          business_payloads: {
            values: {
              disposition: 'postponed',
              after_disposition_update: afterDispositionUpdateAction === ACTIONS.RESCHEDULE ?
                getReschedulePayload() : getScheduleLaterPayload()
            }
          }
        }
      }
    };
  };

  const submit = () => {
    if (isPosting) {
      return;
    }

    setIsPosting(true);

    return props.requestPatch(`/tasks/${task.taskId}`, getPayload(), getSuccessMsg()).
      then((resp) => {
        setIsPosting(false);
        props.onReceiveAmaTasks(resp.body.tasks.data);
      }, () => {
        setIsPosting(false);

        showErrorMessage({
          title: 'Unable to postpone hearing.',
          detail: 'Please retry submitting again and contact support if errors persist.'
        });
      });
  };

  return (
    <QueueFlowModal
      title="Postpone Hearing"
      submit={submit}
      validateForm={validateForm}
      pathAfterSubmit={(taskData && taskData.redirect_after) || '/queue'}>
      <RadioField
        name="postponeAfterDispositionUpdateAction"
        hideLabel
        strongLabel
        options={AFTER_DISPOSITION_UPDATE_ACTION_OPTIONS}
        onChange={(option) => setAfterDispositionUpdateAction(option)}
        value={afterDispositionUpdateAction}
      />

      {afterDispositionUpdateAction === ACTIONS.RESCHEDULE &&
      <AssignHearingForm
        appeal={appeal}
        initialRegionalOffice={appeal.closestRegionalOffice}
        showErrorMessages={showErrorMessages}
      />
      }{afterDispositionUpdateAction === ACTIONS.SCHEDULE_LATER_WITH_ADMIN_ACTION &&
      <ScheduleHearingLaterWithAdminActionForm
        showErrorMessages={showErrorMessages}
        adminActionOptions={taskData ? taskData.options : []}
      />
      }
    </QueueFlowModal>
  );
};

PostponeHearingModal.propTypes = {
  appeal: PropTypes.shape({
    closestRegionalOffice: PropTypes.string,
    externalId: PropTypes.string,
    veteranFullName: PropTypes.string
  }),
  assignHearing: PropTypes.shape({
    apiFormattedValues: PropTypes.shape({
      scheduled_time_string: PropTypes.string,
      hearing_day_id: PropTypes.string,
      hearing_location: PropTypes.string
    }),
    errorMessages: PropTypes.shape({
      hasErrorMessages: PropTypes.bool
    }),
    hearingDay: PropTypes.shape({
      hearingDate: PropTypes.string
    })
  }),
  onReceiveAmaTasks: PropTypes.func,
  onReceiveAppealDetails: PropTypes.func,
  requestPatch: PropTypes.func,
  scheduleHearingLaterWithAdminAction: PropTypes.shape({
    apiFormattedValues: PropTypes.shape({
      with_admin_action_klass: PropTypes.bool,
      admin_action_instructions: PropTypes.string
    }),
    errorMessages: PropTypes.shape({
      hasErrorMessages: PropTypes.bool
    })
  }),
  showErrorMessage: PropTypes.func,
  task: PropTypes.shape({
    taskId: PropTypes.string
  })
};

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  appeal: appealWithDetailSelector(state, ownProps)
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  onReceiveAmaTasks,
  showErrorMessage,
  onReceiveAppealDetails
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(PostponeHearingModal)));
