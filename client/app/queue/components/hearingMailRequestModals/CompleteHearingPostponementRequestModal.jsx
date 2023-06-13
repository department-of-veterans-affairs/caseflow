import React, { useReducer } from 'react';
import PropTypes from 'prop-types';

import Alert from 'app/components/Alert';
import DateSelector from 'app/components/DateSelector';
import QueueFlowModal from '../QueueFlowModal';
import RadioField from '../../../components/RadioField';
import TextareaField from 'app/components/TextareaField';

const CompleteHearingPostponementRequestModal = (props) => {
  const formReducer = (state, action) => {
    switch (action.type) {
    case 'granted':
      return {
        ...state,
        granted: action.payload,
        // If granted is being set to false then reset scheduleOption to null
        ...(action.payload || { scheduleOption: null })
      };
    case 'rulingDate':
      return { ...state, date: action.payload };
    case 'scheduleOption':
      return { ...state, scheduleOption: action.payload };
    case 'instructions':
      return { ...state, instructions: action.payload };
    default:
      throw new Error("Whatever you passed this reducer made it really angry. Please don't do it again.");
    }
  };

  const [state, dispatch] = useReducer(
    formReducer,
    {
      granted: null,
      date: null,
      scheduleOption: null,
      instructions: null
    }
  );

  const submit = () => console.log('Submitting');

  const validateForm = () => false;

  return (
    <QueueFlowModal
      title="Mark as complete"
      button="Mark as complete"
      submitDisabled={!validateForm}
      validateForm={validateForm}
      submit={submit}
      pathAfterSubmit="/organizations/hearing-admin"
    >
      <>
        {/* Granted/Denied */}
        <RadioField
          id="grantedOrDeniedField"
          label="What is the Judge's ruling on the motion to postpone?:"
          inputRef={props.register}
          onChange={(value) => dispatch({ type: 'granted', payload: value === 'true' })}
          value={state.granted}
          options={[
            { displayText: 'Granted', value: true },
            { displayText: 'Denied', value: false }
          ]}
        />

        {/* TODO: Fix the margin-top on this banner */}
        {state.granted && <Alert
          message="By marking this task as complete, you will postpone the hearing."
          type="info"
          lowerMargin
        />}

        {/* Date picker */}
        <DateSelector
          label="Date of ruling:"
          name="rulingDateSelector"
          onChange={(value) => dispatch({ type: 'rulingDate', payload: value === 'true' })}
          value={state.date}
          type="date"
          noFutureDates
        />

        {/* How would you like to proceed? */}
        {state.granted && <RadioField
          id="scheduleOptionField"
          label="How would you like to proceed?:"
          inputRef={props.register}
          onChange={(value) => dispatch({ type: 'scheduleOption', payload: value })}
          value={state.granted}
          options={[
            // See links for the corresponding options over in the PostponeHearingModal component
            // These options will need to trigger the same behavior.
            { displayText: 'Reschedule immediately', value: 'now' }, // https://github.com/department-of-veterans-affairs/caseflow/blob/4fa0a746d2542c6c3f76d59d4764810459f09783/client/app/queue/components/PostponeHearingModal.jsx#L30-L33
            { displayText: 'Send to Schedule Veteran list', value: 'later' } // https://github.com/department-of-veterans-affairs/caseflow/blob/4fa0a746d2542c6c3f76d59d4764810459f09783/client/app/queue/components/PostponeHearingModal.jsx#L34-L37
          ]}
          vertical
        />}

        {/* Additional instructions */}
        <TextareaField
          label="Provide instructions and context for this action:"
          name="instructionsField"
          id="completePostponementInstructions"
          onChange={(value) => dispatch({ type: 'instructions', payload: value })}
          value={state.instructions}
        />
      </>
    </QueueFlowModal>
  );
};

CompleteHearingPostponementRequestModal.propTypes = {
  register: PropTypes.func
};

export default CompleteHearingPostponementRequestModal;
