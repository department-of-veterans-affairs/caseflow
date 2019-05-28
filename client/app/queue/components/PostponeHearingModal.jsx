import * as React from 'react';
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
import { taskActionData, prepareAppealForStore } from '../utils';
import TASK_STATUSES from '../../../constants/TASK_STATUSES.json';

import RadioField from '../../components/RadioField';
import AssignHearingForm from '../../hearings/components/modalForms/AssignHearingForm';
import ScheduleHearingLaterWithAdminActionForm from
  '../../hearings/components/modalForms/ScheduleHearingLaterWithAdminActionForm';
import ApiUtil from '../../util/ApiUtil';

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

class PostponeHearingModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      afterDispositionUpdateAction: '',
      showErrorMessages: false,
      isPosting: false
    };
  }

  validateRescheduleValues = () => {
    const { errorMessages: { hasErrorMessages } } = this.props.assignHearing;

    this.setState({ showErrorMessages: hasErrorMessages });

    return !hasErrorMessages;
  }

  validateScheduleLaterValues = () => {
    const { errorMessages: { hasErrorMessages } } = this.props.scheduleHearingLaterWithAdminAction;

    this.setState({ showErrorMessages: hasErrorMessages });

    return !hasErrorMessages;
  }

  validateForm = () => {
    if (this.state.afterDispositionUpdateAction === ACTIONS.RESCHEDULE) {
      return this.validateRescheduleValues();
    } else if (this.state.afterDispositionUpdateAction === ACTIONS.SCHEDULE_LATER_WITH_ADMIN_ACTION) {
      return this.validateScheduleLaterValues();
    }

    return true;
  }

  getReschedulePayload = () => {
    const {
      apiFormattedValues: { scheduled_time_string, hearing_day_id, hearing_location }
    } = this.props.assignHearing;

    return {
      action: ACTIONS.RESCHEDULE,
      new_hearing_attrs: {
        scheduled_time_string,
        hearing_day_id,
        hearing_location
      }
    };
  }

  getScheduleLaterPayload = () => {
    const { afterDispositionUpdateAction } = this.state;

    if (afterDispositionUpdateAction === ACTIONS.SCHEDULE_LATER_WITH_ADMIN_ACTION) {
      const {
        apiFormattedValues: { with_admin_action_klass, admin_action_instructions }
      } = this.props.scheduleHearingLaterWithAdminAction;

      return {
        action: ACTIONS.SCHEDULE_LATER,
        with_admin_action_klass,
        admin_action_instructions
      };
    }

    return {
      action: ACTIONS.SCHEDULE_LATER
    };
  }

  getPayload = () => {
    const { afterDispositionUpdateAction } = this.state;

    return {
      data: {
        task: {
          status: TASK_STATUSES.cancelled,
          business_payloads: {
            values: {
              disposition: 'postponed',
              after_disposition_update: afterDispositionUpdateAction === ACTIONS.RESCHEDULE ?
                this.getReschedulePayload() : this.getScheduleLaterPayload()
            }
          }
        }
      }
    };
  }

  getSuccessMsg = () => {
    const { afterDispositionUpdateAction } = this.state;
    const { assignHearing: { hearingDay }, appeal } = this.props;

    if (afterDispositionUpdateAction === ACTIONS.RESCHEDULE) {
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
    if (this.state.isPosting) {
      return;
    }

    const { task } = this.props;
    const payload = this.getPayload();

    this.setState({ isPosting: true });

    return this.props.requestPatch(`/tasks/${task.taskId}`, payload, this.getSuccessMsg()).
      then((resp) => {
        this.setState({ isPosting: false });
        const response = JSON.parse(resp.text);

        this.props.onReceiveAmaTasks(response.tasks.data);
      }, () => {
        this.setState({ isPosting: false });

        this.props.showErrorMessage({
          title: 'Unable to postpone hearing.',
          detail: 'Please retry submitting again and contact support if errors persist.'
        });
      });
  }

  resetAppealDetails = () => {
    const { appeal } = this.props;

    ApiUtil.get(`/appeals/${appeal.externalId}`).then((response) => {
      this.props.onReceiveAppealDetails(prepareAppealForStore([response.body.appeal]));
    });
  }

  render = () => {
    const { appeal } = this.props;
    const { afterDispositionUpdateAction, showErrorMessages } = this.state;
    const taskData = taskActionData(this.props);

    return (
      <QueueFlowModal
        title="Postpone Hearing"
        submit={this.submit}
        validateForm={this.validateForm}
        pathAfterSubmit={(taskData && taskData.redirect_after) || '/queue'}>
        <RadioField
          name="postponeAfterDispositionUpdateAction"
          hideLabel
          strongLabel
          options={AFTER_DISPOSITION_UPDATE_ACTION_OPTIONS}
          onChange={(option) => this.setState({ afterDispositionUpdateAction: option })}
          value={afterDispositionUpdateAction}
        />

        {afterDispositionUpdateAction === ACTIONS.RESCHEDULE &&
        <AssignHearingForm
          initialRegionalOffice={appeal.closestRegionalOffice}
          showErrorMessages={showErrorMessages}
          appeal={appeal}
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
}

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  appeal: appealWithDetailSelector(state, ownProps),
  scheduleHearingLaterWithAdminAction: state.components.forms.scheduleHearingLaterWithAdminAction || {},
  assignHearing: state.components.forms.assignHearing || {}
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  onReceiveAmaTasks,
  showErrorMessage,
  onReceiveAppealDetails
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(PostponeHearingModal)));
