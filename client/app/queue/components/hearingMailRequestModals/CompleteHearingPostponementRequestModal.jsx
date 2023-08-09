import React, { useReducer } from 'react';
import PropTypes from 'prop-types';

import COPY from '../../../../COPY';
import QueueFlowModal from '../QueueFlowModal';
import RadioField from '../../../components/RadioField';
import Alert from '../../../components/Alert';
import DateSelector from '../../../components/DateSelector';
import TextareaField from '../../../components/TextareaField';

import { withRouter } from 'react-router-dom';
import { connect } from 'react-redux';
import { taskById, appealWithDetailSelector} from '../../selectors';

import { marginTop, marginBottom } from '../../constants';

import { setScheduledHearing } from '../../../components/common/actions';

import { bindActionCreators } from 'redux';

const RULING_OPTIONS = [
  { displayText: 'Granted', value: true },
  { displayText: 'Denied', value: false }
];

const ACTIONS = {
  RESCHEDULE: 'reschedule',
  SCHEDULE_LATER: 'schedule_later'
};

const POSTPONEMENT_ACTIONS = [
  { displayText: 'Reschedule immediately', value: ACTIONS.RESCHEDULE },
  { displayText: 'Send to Schedule Veteran list', value: ACTIONS.SCHEDULE_LATER }
];

const CompleteHearingPostponementRequestModal = (props) => {
  const { appealId, taskId } = props;
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
      scheduledOption: null
    }
  );

  const validateForm = () => {
    const { granted, rulingDate, instructions, scheduledOption } = state;

    if (granted) {
      return rulingDate.valid && instructions !== '' && scheduledOption !== null;
    }

    return granted !== null && rulingDate.valid && instructions !== '';
  };

  const submit = () => {
    props.history.push(
      `/queue/appeals/${appealId}/tasks/${taskId}/schedule_veteran`
    );
  }

  return (
    <QueueFlowModal
      title="Mark as complete"
      button="Mark as complete"
      submitDisabled={!validateForm()}
      validateForm={validateForm}
      submit={submit}
      pathAfterSubmit="/organizations/hearing-admin"
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
          options={POSTPONEMENT_ACTIONS}
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
  // scheduleHearingLaterWithAdminAction:
  //   state.components.forms.scheduleHearingLaterWithAdminAction || {}
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      setScheduledHearing,
      // requestPatch,
      // onReceiveAmaTasks,
      // showErrorMessage
    },
    dispatch
  );

CompleteHearingPostponementRequestModal.propTypes = {
  register: PropTypes.func,
  appeal: PropTypes.string.isRequired,
  task: PropTypes.string.isRequired,
  history: PropTypes.object
};

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(CompleteHearingPostponementRequestModal)
);
