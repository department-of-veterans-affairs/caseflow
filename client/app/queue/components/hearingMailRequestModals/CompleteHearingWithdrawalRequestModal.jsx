import React from 'react';
import PropTypes from 'prop-types';
import QueueFlowModal from '../QueueFlowModal';
import TextareaField from '../../../components/TextareaField';
import COPY from '../../../../COPY';

const CompleteHearingWithdrawalRequestModal = (props) => {
  const validateForm = () => {
    return true;
  };

  const submit = () => {
    console.log(props);
    console.log('submit!');
  };

  return (
    <QueueFlowModal
      title="Mark as complete"
      button="Mark as complete"
      submitDisabled={!validateForm()}
      validateForm={validateForm}
      submit={submit}
      // pathAfterSubmit={`/queue/appeals/${appealId}`}
    >
      <TextareaField
        label={`${COPY.PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL}:`}
        name="instructionsField"
        id="completePostponementInstructions"
        // onChange={(value) => dispatch({ type: 'instructions', payload: value })}
        // value={state.instructions}
        // styling={marginBottom(0)}
      />
    </QueueFlowModal>
  );
};

CompleteHearingWithdrawalRequestModal.propTypes = {
  register: PropTypes.func
};

export default CompleteHearingWithdrawalRequestModal;
