import React, { useReducer } from 'react';
import PropTypes from 'prop-types';
import ValidatorsUtil from '../../../util/ValidatorsUtil';

import QueueFlowModal from '../QueueFlowModal';
import RadioField from '../../../components/RadioField';
import Alert from '../../../components/Alert';
import DateSelector from '../../../components/DateSelector';
import TextareaField from '../../../components/TextareaField';

import { marginTop, marginBottom } from '../../constants';

const CompleteHearingPostponementRequestModal = (props) => {
  const { futureDate } = ValidatorsUtil;

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
        date: action.payload
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
      }
    default:
      throw new Error('Unknown action type');
    }
  };

  const [state, dispatch] = useReducer(
    formReducer,
    {
      granted: null,
      date: '',
      instructions: '',
      scheduledOption: null
    }
  );

  const validateDate = (date) => date !== '' && !futureDate(date);

  const validateForm = () => {
    const { granted, date, instructions, scheduledOption } = state;

    if (granted) {
      return validateDate(date) && instructions !== '' && scheduledOption !== '';
    }

    return granted !== null && validateDate(date) && instructions !== '';
  };

  const submit = () => console.log(props);

  const GRANTED_OR_DENIED_OPTIONS = [
    { displayText: 'Granted', value: true },
    { displayText: 'Denied', value: false }
  ];

  const RESCHEDULE_HEARING_OPTIONS = [
    { displayText: 'Reschedule immediately', value: 'schedule_now' },
    { displayText: 'Send to Schedule Veteran list', value: 'schedule_later' }
  ];

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
          options={GRANTED_OR_DENIED_OPTIONS}
        />

        {state.granted && <Alert
          message="By marking this task as complete, you will postpone the hearing"
          type="info"
          lowerMargin
          styling={marginTop(0)}
        />}

        <DateSelector
          label="Date of ruling:"
          name="rulingDateSelector"
          onChange={(value) => dispatch({ type: 'rulingDate', payload: value })}
          value={state.date}
          type="date"
          noFutureDates
        />

        {state.granted && <RadioField
          id="scheduleOptionField"
          name="schedulOptionField"
          label="How would you like to proceed?:"
          inputRef={props.register}
          onChange={(value) => dispatch({ type: 'scheduledOption', payload: value })}
          value={state.scheduledOption}
          options={RESCHEDULE_HEARING_OPTIONS}
          vertical
          styling={marginBottom(1)}
        />}

        <TextareaField
          label="Provide instructions and context for this action:"
          name="instructionsField"
          id="completePostponementInstructions"
          onChange={(value) => dispatch({ type: 'instructions', payload: value })}
        />
      </>
    </QueueFlowModal>
  );
};

CompleteHearingPostponementRequestModal.propTypes = {
  register: PropTypes.func
};

export default CompleteHearingPostponementRequestModal;
