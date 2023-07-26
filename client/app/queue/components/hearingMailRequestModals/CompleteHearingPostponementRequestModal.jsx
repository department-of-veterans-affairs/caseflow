import React, { useReducer } from 'react';
// import PropTypes from 'prop-types';
import COPY from '../../../../COPY';

import QueueFlowModal from '../QueueFlowModal';
import RadioField from '../../../components/RadioField';

const CompleteHearingPostponementRequestModal = (props) => {
  const formReducer = (state, action) => {
    switch (action.type) {
      case 'granted':
        return {
          ...state,
          granted: action.payload
        };
      default:
        throw new Error("Unknown action type");
    }
  };

  const [state, dispatch] = useReducer(
    formReducer,
    {
      granted: null,
    }
  );

  const validateForm = () => false;

  const submit = () => console.log(props);

  console.log(state);

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
        label={COPY.COMPLETE_HEARING_POSTPONEMENT_REQUEST}
        inputRef={props.register}
        onChange={(value) => dispatch({ type: 'granted', payload: value === 'true' })}
        value={state.granted}
        options={[
          { displayText: 'Granted', value: true },
          { displayText: 'Denied', value: false }
        ]}
      />
    </QueueFlowModal>
  );
};

export default CompleteHearingPostponementRequestModal;
