import React, { useReducer } from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../../COPY';

import QueueFlowModal from '../QueueFlowModal';
import RadioField from '../../../components/RadioField';
import Alert from '../../../components/Alert';
import DateSelector from '../../../components/DateSelector';

const CompleteHearingPostponementRequestModal = (props) => {
  const formReducer = (state, action) => {
    switch (action.type) {
    case 'granted':
      return {
        ...state,
        granted: action.payload
      };
    case 'rulingDate':
      return {
        ...state,
        date: action.payload
      }
    default:
      throw new Error('Unknown action type');
    }
  };

  const [state, dispatch] = useReducer(
    formReducer,
    {
      granted: null,
      date: null
    }
  );

  const validateForm = () => false;

  const submit = () => console.log(props);

  return (
    <QueueFlowModal
      title="Mark as complete"
      button="Mark as complete"
      submitDisabled={!validateForm}
      validateForm={validateForm}
      submit={submit}
      pathAfterSubmit="/organizations/hearing-admin"
    >

      <RadioField
        id="grantedOrDeniedField"
        label="What is the Judge’s ruling on the motion to postpone?"
        inputRef={props.register}
        onChange={(value) => dispatch({ type: 'granted', payload: value === 'true' })}
        value={state.granted}
        options={[
          { displayText: 'Granted', value: true },
          { displayText: 'Denied', value: false }
        ]}
      />

      {state.granted && <Alert
        message="By marking this task as complete, you will postpone the hearing"
        type="info"
        lowerMargin
      />}

      <DateSelector
        label="Date of ruling:"
        name="rulingDateSelector"
        onChange={(value) => dispatch({ type: 'rulingDate', payload: value })}
        value={state.date}
        type="date"
        noFutureDates
      />
    </QueueFlowModal>
  );
};

CompleteHearingPostponementRequestModal.propTypes = {
  register: PropTypes.func
};

export default CompleteHearingPostponementRequestModal;
