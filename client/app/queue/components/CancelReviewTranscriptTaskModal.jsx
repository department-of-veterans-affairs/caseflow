import React, { useState, useEffect } from 'react';
import { useDispatch } from 'react-redux';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
import Button from '../../components/Button';
import TextareaField from '../../components/TextareaField';
import COPY from '../../../COPY';
import { requestPatch } from '../uiReducer/uiActions';

const CancelReviewTranscriptTaskModal = (props) => {
  const [isSubmitDisabled, setIsSubmitDisabled] = useState(true);
  const [notes, setNotes] = useState('');
  const dispatch = useDispatch();

  useEffect(() => {
    setIsSubmitDisabled(notes === '');
  }, [notes]);

  const cancel = () => {
    props.closeModal();
  };

  const submit = () => {
    const formatInstructions = () => {
      return [
        COPY.REVIEW_TRANSCRIPT_TASK_DEFAULT_INSTRUCTIONS,
        COPY.UPLOAD_TRANSCRIPTION_VBMS_CANCEL_ACTION_TYPE,
        notes
      ];
    };

    const requestParams = () => {
      return {
        data: {
          task: {
            instructions: formatInstructions()
          }
        }
      };
    };

    dispatch(
      requestPatch(
        `/tasks/${props.taskId}/cancel_review_transcript_task`,
        requestParams()
      )
    ).then(() => {
      props.closeModal();
    });
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

