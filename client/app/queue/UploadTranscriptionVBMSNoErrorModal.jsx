import React, { useState, useEffect } from 'react';
import { useDispatch } from 'react-redux';
import PropTypes from 'prop-types';

import Modal from '../components/Modal';
import Button from '../components/Button';
import TextareaField from '../components/TextareaField';
import COPY from '../../COPY';
import { requestPatch } from './uiReducer/uiActions';

const UploadTranscriptionVBMSNoErrorModal = (props) => {
  const [isSubmitDisabled, setIsSubmitDisabled] = useState(true);
  const [notes, setNotes] = useState('');
  const dispatch = useDispatch();

  useEffect(() => {
    setIsSubmitDisabled(notes === '');
  }, [notes]);

  const cancel = () => {
    props.closeModal();
  };

  const redirectAfterSubmit = () => {
    window.location = `/queue/appeals/${props.appealId}`;
  };

  const submit = () => {
    const formatInstructions = () => {
      return [
        COPY.REVIEW_TRANSCRIPT_TASK_DEFAULT_INSTRUCTIONS,
        COPY.UPLOAD_TRANSCRIPTION_VBMS_NO_ERRORS_ACTION_TYPE,
        notes
      ];
    };

    const requestParams = () => {
      return {
        data: {
          task: { instructions: formatInstructions() },
          appeal_id: props.appealId
        }
      };
    };

    dispatch(
      requestPatch(`/tasks/${props.taskId}/upload_transcription_to_vbms`, requestParams())
    ).then(() => {
      redirectAfterSubmit();
    });
  };

  const handleTextareaFieldChange = (event) => {
    setNotes(event);
  };

  return (
    <Modal
      title={COPY.UPLOAD_TRANSCRIPTION_VBMS_TITLE}
      closeHandler={cancel}
      confirmButton={
        <Button
          disabled={isSubmitDisabled}
          onClick={submit}>{COPY.UPLOAD_TRANSCRIPTION_VBMS_BUTTON}
        </Button>
      }
      cancelButton={<Button linkStyling onClick={cancel}>Cancel</Button>}
    >
      <p>{COPY.UPLOAD_TRANSCRIPTION_VBMS_TEXT}</p>
      <div className="comment-size-container">
        <TextareaField
          id="cf-form-textarea"
          name={COPY.UPLOAD_TRANSCRIPTION_VBMS_TEXT_AREA}
          onChange={handleTextareaFieldChange}
          value={notes}
        />
      </div>
    </Modal>
  );
};

UploadTranscriptionVBMSNoErrorModal.propTypes = {
  closeModal: PropTypes.func,
  taskId: PropTypes.string,
  appealId: PropTypes.string
};

export default UploadTranscriptionVBMSNoErrorModal;
