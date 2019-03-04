import * as React from 'react';
import { formatDateStr } from '../../util/DateUtil';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';

import {
  taskById,
  appealWithDetailSelector
} from '../selectors';
import { onReceiveAmaTasks } from '../QueueActions';
import {
  requestPatch
} from '../uiReducer/uiActions';
import editModalBase from './EditModalBase';
import { taskActionData } from '../utils';
import TASK_STATUSES from '../../../constants/TASK_STATUSES.json';

import RadioField from '../../components/RadioField';
import AssignHearingForm from '../../hearingSchedule/components/modalForms/AssignHearingForm';
import ScheduleHearingLaterWithAdminActionForm from
  '../../hearingSchedule/components/modalForms/ScheduleHearingLaterWithAdminActionForm';

const AFTER_DISPOSITION_UPDATE_ACTION_OPTIONS = [
  {
    displayText: 'Reschedule immediately',
    value: 'reschedule'
  },
  {
    displayText: 'Send to Schedule Veteran list',
    value: 'schedule_later'
  },
  {
    displayText: 'Apply admin action',
    value: 'schedule_later_with_admin_action'
  }
];

class PostponeHearingModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      afterDispositionUpdateAction: '',
      showErrorMessages: false
    };
  }

  validateRescheduleValues = () => {
    const { errorMessages: { hasErrorMessages } } = this.props.assignHearing;

    this.setState({ showErrorMessages: hasErrorMessages });

    return hasErrorMessages;
  }

  validateScheduleLaterValues = () => {
    const { errorMessages: { hasErrorMessages } } = this.props.scheduleHearingLaterWithAdminAction;

    this.setState({ showErrorMessages: hasErrorMessages });

    return hasErrorMessages;
  }

  validateForm = () => {

    if (this.state.afterDispositionUpdateAction === 'reschedule') {
      return this.validateRescheduleValues();
    } else if (this.state.afterDispositionUpdateAction === 'schedule_later_with_admin_action') {
      return this.validateScheduleLaterValues();
    }

    return true;
  }

  getReschedulePayload = () => {
    const { apiFormattedValues: { hearing_time, hearing_day_id, hearing_location } } = this.props.assignHearing;

    return {
      action: 'reschedule',
      new_hearing_attrs: {
        hearing_time,
        hearing_pkseq: hearing_day_id,
        hearing_location
      }
    };
  }

  getScheduleLaterPayload = () => {
    const { withAdminActionKlass, adminActionInstructions } = this.props.scheduleHearingLaterWithAdminAction;

    return {
      action: 'schedule_later',
      with_admin_action_klass: withAdminActionKlass,
      admin_action_instructions: adminActionInstructions
    };
  }

  getAfterDispositionUpdatePayload = () => {
    const { afterDispositionUpdateAction } = this.state;

    if (afterDispositionUpdateAction.value === 'reschedule') {
      return this.getReschedulePayload();
    }

    return this.getScheduleLaterPayload();
  }

  getPayload = () => {
    return {
      data: {
        status: TASK_STATUSES.cancelled,
        business_payloads: {
          values: {
            disposition: 'postponed',
            after_disposition_update: this.getAfterDispositionUpdatePayload()
          }
        }
      }
    };
  }

  getSuccessMsg = () => {
    const { afterDispositionUpdateAction } = this.state;
    const { assignHearing: { hearingDay }, appeal } = this.props;

    if (afterDispositionUpdateAction === 'reschedule') {
      const hearingDateStr = formatDateStr(hearingDay.hearingDate, 'YYYY-MM-DD', 'MM/DD/YYYY');
      const title = `You have successfully assigned ${appeal.veteranFullName} ` +
                    `to a hearing on ${hearingDateStr}.`;

      return { title };
    }

    return {
      title: `${appeal.veteranFullName} was successfully added back to the schedule veteran list.`
    };
  }

  submit = () => {
    const { task } = this.props;
    const payload = this.getPayload();

    return this.props.requestPatch(`/tasks/${task.taskId}`, payload, this.getSuccessMsg()).
      then((resp) => {
        const response = JSON.parse(resp.text);

        this.props.onReceiveAmaTasks(response.tasks.data);
      });
  }

  render = () => {
    const { appeal } = this.props;
    const { afterDispositionUpdateAction, showErrorMessages } = this.state;
    const taskData = taskActionData(this.props);

    return (
      <div>
        <RadioField
          name="postponeAfterDispositionUpdateAction"
          hideLabel
          strongLabel
          options={AFTER_DISPOSITION_UPDATE_ACTION_OPTIONS}
          onChange={(option) => this.setState({ afterDispositionUpdateAction: option })}
          value={afterDispositionUpdateAction}
        />

        {afterDispositionUpdateAction === 'reschedule' &&
        <AssignHearingForm
          showErrorMessages={showErrorMessages}
          appeal={appeal}
        />
        }{afterDispositionUpdateAction === 'schedule_later_with_admin_action' &&
        <ScheduleHearingLaterWithAdminActionForm
          showErrorMessages={showErrorMessages}
          adminActionOptions={taskData ? taskData.options : []}
        />
        }
      </div>
    );
  };
}

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  appeal: appealWithDetailSelector(state, ownProps),
  scheduleHearingLaterWithAdminAction: state.components.forms.scheduleHearingLaterWithAdminAction || {},
  assignHearing: state.components.forms.assignHearing || {}
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  onReceiveAmaTasks
}, dispatch);

const propsToText = (props) => {
  const taskData = taskActionData(props);

  const pathAfterSubmit = (taskData && taskData.redirect_after) || '/queue';

  return {
    title: 'Postpone Hearing',
    pathAfterSubmit
  };
};

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(editModalBase(
    PostponeHearingModal, { propsToText }
  ))
));
