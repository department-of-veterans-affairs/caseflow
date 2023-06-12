import React, { useReducer } from 'react';
import PropTypes from 'prop-types';

import QueueFlowModal from '../QueueFlowModal';
import RadioField from '../../../components/RadioField';
import TextareaField from 'app/components/TextareaField';

const CompleteHearingPostponementRequestModal = (props) => {
  const formReducer = (state, action) => {
    switch (action.type) {
    case 'granted':
      return { ...state, granted: action.payload }
    case 'date':
      return { ...state, date: action.payload }
    case 'schedule-option':
      return { ...state, scheduleOption: action.payload }
    case 'instructions':
      return { ...state, instructions: action.payload }
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

  const submit = () => console.log("Submitting");

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
        <RadioField />

        {/* Date picker */}

        {/* How would you like to proceed? */}

        {/* Additional instructions */}
        <TextareaField
          label="Provide instructions and context for this action:"
          name="instructions"
          id="completePostponementInstructions"
          onChange={(value) => dispatch({ type: 'instructions', payload: value })}
          value={state.instructions}
        />
      </>
    </QueueFlowModal>
  );
};

export default CompleteHearingPostponementRequestModal;
