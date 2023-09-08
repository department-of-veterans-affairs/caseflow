import React, { useState } from 'react';
import PropTypes from 'prop-types';
import QueueFlowModal from '../QueueFlowModal';
import TextareaField from '../../../components/TextareaField';
import COPY from '../../../../COPY';

const CompleteHearingWithdrawalRequestModal = (props) => {
  const [instructions, setInstructions] = useState('');

  const validateForm = () => {
    return instructions !== '';
  };

  const submit = () => console.log(props);

  return (
    <QueueFlowModal
      title="Mark as complete and withdraw hearing"
      button="Mark as complete & withdraw hearing"
      submitDisabled={!validateForm()}
      validateForm={validateForm}
      submit={submit}
      // pathAfterSubmit={`/queue/appeals/${appealId}`}
    >
      <div>By marking this task as complete, you will withdraw the hearing</div>
      <br />
      <div>{COPY.WITHDRAW_HEARING.AMA.MODAL_BODY}</div>
      <br />
      <TextareaField
        label={`${COPY.PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL}:`}
        name="instructionsField"
        id="completePostponementInstructions"
        onChange={setInstructions}
        value={instructions}
      />
    </QueueFlowModal>
  );
};

CompleteHearingWithdrawalRequestModal.propTypes = {
  register: PropTypes.func
};

export default CompleteHearingWithdrawalRequestModal;
