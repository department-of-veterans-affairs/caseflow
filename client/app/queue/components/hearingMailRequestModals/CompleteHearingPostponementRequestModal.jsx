import React, { useReducer } from 'react';
import PropTypes from 'prop-types';
import { withRouter } from 'react-router-dom';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { taskById, appealWithDetailSelector } from '../../selectors';
import { requestPatch, showErrorMessage } from '../../uiReducer/uiActions';
import { onReceiveAmaTasks } from '../../QueueActions';
import COPY from '../../../../COPY';
import TASK_STATUSES from '../../../../constants/TASK_STATUSES';
import HEARING_DISPOSITION_TYPES from '../../../../constants/HEARING_DISPOSITION_TYPES';
import QueueFlowModal from '../QueueFlowModal';
import RadioField from '../../../components/RadioField';
import Alert from '../../../components/Alert';
import DateSelector from '../../../components/DateSelector';
import TextareaField from '../../../components/TextareaField';
import { marginTop, marginBottom } from '../../constants';
import { setScheduledHearing } from '../../../components/common/actions';

const ACTIONS = {
  RESCHEDULE: 'reschedule',
  SCHEDULE_LATER: 'schedule_later'
};

const RULING_OPTIONS = [
  { displayText: 'Granted', value: true },
  { displayText: 'Denied', value: false }
];

const POSTPONEMENT_OPTIONS = [
  { displayText: 'Reschedule immediately', value: ACTIONS.RESCHEDULE },
  { displayText: 'Send to Schedule Veteran list', value: ACTIONS.SCHEDULE_LATER }
];

const CompleteHearingPostponementRequestModal = (props) => {
  const { appealId, appeal, taskId, task, userCanScheduleVirtualHearings } = props;

  const formReducer = (state, action) => {
    switch (action.type) {
    case 'granted':
      return {
        ...state,
        granted: action.payload,
        scheduledOption: null
      };
    case 'rulingDate':
      return {
        ...state,
        rulingDate: { ...state.rulingDate, value: action.payload }
      };
    case 'dateIsValid':
      return {
        ...state,
        rulingDate: { ...state.rulingDate, valid: action.payload }
      };
    case 'instructions':
      return {
        ...state,
        instructions: action.payload
      };
    case 'scheduledOption':
      return {
        ...state,
        scheduledOption: action.payload
      };
    case 'isPosting':
      return {
        ...state,
        isPosting: action.payload
      };
    default:
      throw new Error('Unknown action type');
    }
  };

  const [state, dispatch] = useReducer(
    formReducer,
    {
      granted: null,
      rulingDate: { value: '', valid: false },
      instructions: '',
      scheduledOption: null,
      isPosting: false
    }
  );

  const validateForm = () => {
    const { granted, rulingDate, instructions, scheduledOption } = state;

    if (granted) {
      return rulingDate.valid && instructions !== '' && scheduledOption !== null;
    }

    return granted !== null && rulingDate.valid && instructions !== '';
  };

  const getPayload = () => {
    const { granted, rulingDate, instructions } = state;

    return {
      data: {
        task: {
          status: TASK_STATUSES.completed,
          instructions,
          business_payloads: {
            values: {
              // If request is denied, do not assign new disposition to hearing
              disposition: granted ? HEARING_DISPOSITION_TYPES.postponed : null,
              after_disposition_update: granted ? { action: ACTIONS.SCHEDULE_LATER } : null,
              date_of_ruling: rulingDate.value,
            },
          },
        },
      },
    };
  };

  const getSuccessMsg = () => {
    return {
      title: `${
        appeal.veteranFullName
      } was successfully added back to the schedule veteran list.`,
    };
  };

  const submit = () => {
    const { isPosting, granted, scheduledOption } = state;

    if (granted && scheduledOption === ACTIONS.RESCHEDULE && userCanScheduleVirtualHearings) {
      props.setScheduledHearing({
        action: ACTIONS.RESCHEDULE,
        taskId,
        disposition: HEARING_DISPOSITION_TYPES.postponed
      });

      props.history.push(
        `/queue/appeals/${appealId}/tasks/${taskId}/schedule_veteran`
      );

      return Promise.reject();
    }

    if (isPosting) {
      return;
    }

    const payload = getPayload();

    dispatch({ type: 'isPosting', payload: true });

    return props.
      requestPatch(`/tasks/${task.taskId}`, payload, getSuccessMsg()).
      then(
        (resp) => {
          dispatch({ type: 'isPosting', payload: false });
          props.onReceiveAmaTasks(resp.body.tasks.data);
        },
        () => {
          dispatch({ type: 'isPosting', payload: false });

          props.showErrorMessage({
            title: 'Unable to postpone hearing.',
            detail:
              'Please retry submitting again and contact support if errors persist.',
          });
        }
      );
  };

  return (
    <QueueFlowModal
      title="Mark as complete"
      button="Mark as complete"
      submitDisabled={!validateForm()}
      validateForm={validateForm}
      submit={submit}
      pathAfterSubmit={`/queue/appeals/${appealId}`}
    >
      <>
        <RadioField
          id="grantedOrDeniedField"
          name="grantedOrDeniedField"
          label="What is the Judge’s ruling on the motion to postpone?"
          inputRef={props.register}
          onChange={(value) => dispatch({ type: 'granted', payload: value === 'true' })}
          value={state.granted}
          options={RULING_OPTIONS}
          styling={marginBottom(1)}
        />

        {state.granted && <Alert
          message="By marking this task as complete, you will postpone the hearing."
          type="info"
          lowerMargin
          styling={marginTop(0)}
        />}

        <DateSelector
          label="Date of ruling:"
          name="rulingDateSelector"
          onChange={(value) => dispatch({ type: 'rulingDate', payload: value })}
          value={state.rulingDate.value}
          type="date"
          noFutureDates
          validateDate={(value) => dispatch({ type: 'dateIsValid', payload: value })}
          inputStyling={marginBottom(1)}
        />

        {state.granted && <RadioField
          id="scheduleOptionField"
          name="scheduleOptionField"
          label="How would you like to proceed?:"
          inputRef={props.register}
          onChange={(value) => dispatch({ type: 'scheduledOption', payload: value })}
          value={state.scheduledOption}
          options={POSTPONEMENT_OPTIONS}
          vertical
          styling={marginBottom(1.5)}
        />}

        <TextareaField
          label={`${COPY.PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL}:`}
          name="instructionsField"
          id="completePostponementInstructions"
          onChange={(value) => dispatch({ type: 'instructions', payload: value })}
          value={state.instructions}
          styling={marginBottom(0)}
        />
      </>
    </QueueFlowModal>
  );
};

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  appeal: appealWithDetailSelector(state, ownProps),
  scheduleHearingLaterWithAdminAction:
    state.components.forms.scheduleHearingLaterWithAdminAction || {}
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

CompleteHearingPostponementRequestModal.propTypes = {
  register: PropTypes.func,
  appealId: PropTypes.string.isRequired,
  taskId: PropTypes.string.isRequired,
  history: PropTypes.object,
  setScheduledHearing: PropTypes.func,
  userCanScheduleVirtualHearings: PropTypes.bool,
  appeal: PropTypes.shape({
    externalId: PropTypes.string,
    veteranFullName: PropTypes.string
  }),
  task: PropTypes.shape({
    taskId: PropTypes.string,
  }),
  requestPatch: PropTypes.func,
  onReceiveAmaTasks: PropTypes.func,
  showErrorMessage: PropTypes.func,
};

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(CompleteHearingPostponementRequestModal)
);
