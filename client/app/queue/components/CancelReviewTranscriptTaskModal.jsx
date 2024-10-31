import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
import Button from '../../components/Button';
import TextareaField from '../../components/TextareaField';

const CancelReviewTranscriptTaskModal = (props) => {
  const [isSubmitDisabled, setIsSubmitDisabled] = useState(true);
  const [notes, setNotes] = useState('');

  useEffect(() => {
    setIsSubmitDisabled(notes === '');
  }, [notes]);

  const cancel = () => {
    props.closeModal();
  };

  const submit = () => {
    // TODO: requestPatch to update the status
  };

  const handleTextareaFieldChange = (event) => {
    setNotes(event);
  };

  return (
    <Modal
      title="Cancel task"
      closeHandler={cancel}
      confirmButton={<Button disabled={isSubmitDisabled} onClick={submit}>Cancel task</Button>}
      cancelButton={<Button linkStyling onClick={cancel}>Cancel</Button>}
    >
      <p>Cancelling this task will permanently remove it from the case's active tasks.</p>
      <div className="comment-size-container">
        <TextareaField
          id="cf-form-textarea"
          name="Please provide context and instructions for this action"
          onChange={handleTextareaFieldChange}
          value={notes}
        />
      </div>
    </Modal>
  );
};

CancelReviewTranscriptTaskModal.propTypes = {
  closeModal: PropTypes.func,
  taskId: PropTypes.string
};

export default CancelReviewTranscriptTaskModal;

