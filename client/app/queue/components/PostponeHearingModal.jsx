import * as React from 'react';
import PropTypes from 'prop-types';
import { formatDateStr } from '../../util/DateUtil';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';

import { taskById, appealWithDetailSelector } from '../selectors';
import { onReceiveAmaTasks } from '../QueueActions';
import { requestPatch, showErrorMessage } from '../uiReducer/uiActions';
import QueueFlowModal from './QueueFlowModal';
import { taskActionData } from '../utils';
import TASK_STATUSES from '../../../constants/TASK_STATUSES';
import { setScheduledHearing } from '../../components/common/actions';

import RadioField from '../../components/RadioField';
import AssignHearingForm from '../../hearings/components/modalForms/AssignHearingForm';
import ScheduleHearingLaterWithAdminActionForm
  from '../../hearings/components/modalForms/ScheduleHearingLaterWithAdminActionForm';

import HEARING_DISPOSITION_TYPES from '../../../constants/HEARING_DISPOSITION_TYPES';

const ACTIONS = {
  RESCHEDULE: 'reschedule',
  SCHEDULE_LATER: 'schedule_later',
  SCHEDULE_LATER_WITH_ADMIN_ACTION: 'schedule_later_with_admin_action',
};

const AFTER_DISPOSITION_UPDATE_ACTION_OPTIONS = [
  {
    displayText: 'Reschedule immediately',
    value: ACTIONS.RESCHEDULE,
  },
  {
    displayText: 'Send to Schedule Veteran list',
    value: ACTIONS.SCHEDULE_LATER,
  },
  {
    displayText: 'Apply admin action',
    value: ACTIONS.SCHEDULE_LATER_WITH_ADMIN_ACTION,
  },
];

class PostponeHearingModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      afterDispositionUpdateAction: '',
      showErrorMessages: false,
      isPosting: false,
    };
  }

  validateRescheduleValues = () => {
    const {
      errorMessages: { hasErrorMessages },
    } = this.props.assignHearing;

    this.setState({ showErrorMessages: hasErrorMessages });

    return !hasErrorMessages;
  };

  validateScheduleLaterValues = () => {
    const {
      errorMessages: { hasErrorMessages },
    } = this.props.scheduleHearingLaterWithAdminAction;

    this.setState({ showErrorMessages: hasErrorMessages });

    return !hasErrorMessages;
  };

  validateForm = () => {
    if (this.state.afterDispositionUpdateAction === ACTIONS.RESCHEDULE && !this.props.userCanScheduleVirtualHearings) {
      return this.validateRescheduleValues();
    } else if (this.state.afterDispositionUpdateAction === ACTIONS.SCHEDULE_LATER_WITH_ADMIN_ACTION) {
      return this.validateScheduleLaterValues();
    }

    return true;
  };

  getReschedulePayload = () => {
    const {
      // eslint-disable-next-line camelcase
      apiFormattedValues: { scheduled_time_string, hearing_day_id, hearing_location },
    } = this.props.assignHearing;

    return {
      action: ACTIONS.RESCHEDULE,
      new_hearing_attrs: {
        scheduled_time_string,
        hearing_day_id,
        hearing_location,
      },
    };
  };

  getScheduleLaterPayload = () => {
    const { afterDispositionUpdateAction } = this.state;

    if (
      afterDispositionUpdateAction === ACTIONS.SCHEDULE_LATER_WITH_ADMIN_ACTION
    ) {
      const {
        // eslint-disable-next-line camelcase
        apiFormattedValues: { with_admin_action_klass, admin_action_instructions },
      } = this.props.scheduleHearingLaterWithAdminAction;

      return {
        action: ACTIONS.SCHEDULE_LATER,
        with_admin_action_klass,
        admin_action_instructions,
      };
    }

    return {
      action: ACTIONS.SCHEDULE_LATER,
    };
  };

  getPayload = () => {
    const { afterDispositionUpdateAction } = this.state;

    return {
      data: {
        task: {
          status: TASK_STATUSES.cancelled,
          business_payloads: {
            values: {
              disposition: HEARING_DISPOSITION_TYPES.postponed,
              after_disposition_update:
                afterDispositionUpdateAction === ACTIONS.RESCHEDULE ?
                  this.getReschedulePayload() :
                  this.getScheduleLaterPayload(),
            },
          },
        },
      },
    };
  };

  getSuccessMsg = () => {
    const { afterDispositionUpdateAction } = this.state;
    const {
      assignHearing: { hearingDay },
      appeal,
    } = this.props;

    if (afterDispositionUpdateAction === ACTIONS.RESCHEDULE) {
      const hearingDateStr = formatDateStr(
        hearingDay.hearingDate,
        'YYYY-MM-DD',
        'MM/DD/YYYY'
      );
      const title =
        `You have successfully assigned ${appeal.veteranFullName} ` +
        `to a hearing on ${hearingDateStr}.`;

      return { title };
    }

    return {
      title: `${
        appeal.veteranFullName
      } was successfully added back to the schedule veteran list.`,
    };
  };

  submit = () => {
    const { userCanScheduleVirtualHearings, appeal, task } = this.props;
    const taskData = taskActionData(this.props);

    // Determine whether to redirect to the ful page schedule veteran flow
    if (this.state.afterDispositionUpdateAction === ACTIONS.RESCHEDULE && userCanScheduleVirtualHearings) {
      // Change the disposition in the store
      this.props.setScheduledHearing({
        action: ACTIONS.RESCHEDULE,
        taskId: task.taskId,
        disposition: HEARING_DISPOSITION_TYPES.postponed
      });

      this.props.history.push(
        `/queue/appeals/${appeal.externalId}/tasks/${task.taskId}/${taskData.schedule_hearing_action_path}`
      );

      // This is a failed Promise to prevent `QueueFlowModal` from thinking the
      // request completed successfully, and redirecting back to the `CaseDetails` page.
      return Promise.reject();
    }

    if (this.state.isPosting) {
      return;
    }

    const payload = this.getPayload();

    this.setState({ isPosting: true });

    return this.props.
      requestPatch(`/tasks/${task.taskId}`, payload, this.getSuccessMsg()).
      then(
        (resp) => {
          this.setState({ isPosting: false });
          this.props.onReceiveAmaTasks(resp.body.tasks.data);
        },
        () => {
          this.setState({ isPosting: false });

          this.props.showErrorMessage({
            title: 'Unable to postpone hearing.',
            detail:
              'Please retry submitting again and contact support if errors persist.',
          });
        }
      );
  };

  render = () => {
    const { appeal, userCanScheduleVirtualHearings } = this.props;
    const { afterDispositionUpdateAction, showErrorMessages } = this.state;
    const taskData = taskActionData(this.props);

    // Determine which Hearing form to render
    const hearingModal = afterDispositionUpdateAction === ACTIONS.RESCHEDULE && !userCanScheduleVirtualHearings;

    return (
      <QueueFlowModal
        title="Postpone Hearing"
        submit={this.submit}
        validateForm={this.validateForm}
        pathAfterSubmit={(taskData && taskData.redirect_after) || '/queue'}
      >
        <RadioField
          name="postponeAfterDispositionUpdateAction"
          hideLabel
          strongLabel
          options={AFTER_DISPOSITION_UPDATE_ACTION_OPTIONS}
          onChange={(option) =>
            this.setState({ afterDispositionUpdateAction: option })
          }
          value={afterDispositionUpdateAction}
        />

        {hearingModal && (
          <AssignHearingForm
            initialRegionalOffice={appeal.closestRegionalOffice}
            showErrorMessages={showErrorMessages}
            appeal={appeal}
          />
        )}
        {afterDispositionUpdateAction ===
          ACTIONS.SCHEDULE_LATER_WITH_ADMIN_ACTION && (
          <ScheduleHearingLaterWithAdminActionForm
            showErrorMessages={showErrorMessages}
            adminActionOptions={taskData ? taskData.options : []}
          />
        )}
      </QueueFlowModal>
    );
  };
}

PostponeHearingModal.propTypes = {
  setScheduledHearing: PropTypes.func,
  appeal: PropTypes.shape({
    closestRegionalOffice: PropTypes.string,
    externalId: PropTypes.string,
    veteranFullName: PropTypes.string,
  }),
  assignHearing: PropTypes.shape({
    apiFormattedValues: PropTypes.shape({
      scheduled_time_string: PropTypes.string,
      hearing_day_id: PropTypes.string,
      hearing_location: PropTypes.string,
    }),
    errorMessages: PropTypes.shape({
      hasErrorMessages: PropTypes.bool,
    }),
    hearingDay: PropTypes.shape({
      hearingDate: PropTypes.string,
    }),
  }),
  onReceiveAmaTasks: PropTypes.func,
  history: PropTypes.object,
  requestPatch: PropTypes.func,
  scheduleHearingLaterWithAdminAction: PropTypes.shape({
    apiFormattedValues: PropTypes.shape({
      with_admin_action_klass: PropTypes.bool,
      admin_action_instructions: PropTypes.string,
    }),
    errorMessages: PropTypes.shape({
      hasErrorMessages: PropTypes.bool,
    }),
  }),
  showErrorMessage: PropTypes.func,
  task: PropTypes.shape({
    taskId: PropTypes.string,
  }),
  userCanScheduleVirtualHearings: PropTypes.bool
};

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  appeal: appealWithDetailSelector(state, ownProps),
  scheduleHearingLaterWithAdminAction:
    state.components.forms.scheduleHearingLaterWithAdminAction || {},
  assignHearing: state.components.forms.assignHearing || {},
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
  )(PostponeHearingModal)
);
