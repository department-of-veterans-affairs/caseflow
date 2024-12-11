import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
import Button from '../../components/Button';
import FileUpload from '../../components/FileUpload';
import TextareaField from '../../components/TextareaField';
import COPY from '../../../COPY';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { requestPatch } from '../uiReducer/uiActions';
import { withRouter } from 'react-router-dom';
import { setAppealAttrs } from '../QueueActions';

import {
  appealWithDetailSelector,
  taskById
} from '../selectors';

export const ErrorsFoundAndCorrectedModal = (props) => {
  const [isSubmitDisabled, setIsSubmitDisabled] = useState(true);
  const [loading, setLoading] = useState(false);
  const [isAnyFileSelected, setIsAnyFileSelected] = useState(false);
  const [selectedFile, setSelectedFile] = useState({});
  const [fileInputContainerClassName, setFileInputContainerClassName] = useState('cf-file-input-container');
  const [notes, setNotes] = useState('');

  useEffect(() => {
    if (loading) {
      setIsSubmitDisabled(true);
    } else if (isAnyFileSelected && notes.trim() !== '') {
      setIsSubmitDisabled(false);
    } else if (notes === '') {
      setIsSubmitDisabled(true);
    }
  }, [loading, isAnyFileSelected, notes]);

  const cancel = () => {
    props.closeModal();
  };

  const redirectAfterSubmit = () => {
    window.location = `/queue/appeals/${props.appealId}`;
  };

  const submit = () => {
    const { task } = props;

    const formatInstructions = () => {
      return [
        COPY.REVIEW_TRANSCRIPT_TASK_DEFAULT_INSTRUCTIONS,
        COPY.UPLOAD_TRANSCRIPTION_VBMS_ERRORS_ACTION_TYPE,
        notes,
        selectedFile.fileName
      ];
    };

    const requestParams = () => {
      return {
        data: {
          task: {
            instructions: formatInstructions()
          },
          file_info: {
            file: selectedFile.file,
            file_name: selectedFile.fileName
          },
          appeal_id: props.appealId
        }
      };
    };

    setLoading(true);

    return props.requestPatch(`/tasks/${task.taskId}
      /error_found_upload_transcription_to_vbms`, requestParams()
    ).then(() => {
      redirectAfterSubmit();
    });
  };

  const handleFileChange = (file) => {
    setIsAnyFileSelected(true);
    setSelectedFile(file);
    setFileInputContainerClassName('cf-file-input-container-selected');
  };

  const handleTextareaFieldChange = (event) => {
    setNotes(event);
  };

  return (
    <Modal
      title="Upload transcript to VBMS"
      closeHandler={cancel}
      confirmButton={<Button disabled={isSubmitDisabled} onClick={submit}>Upload to VBMS</Button>}
      cancelButton={<Button disabled={loading} linkStyling onClick={cancel}>Cancel</Button>}
    >
      <p>Please upload the revised transcript file for upload to VBMS.</p>
      <strong style={{ color: 'black' }}>Please select PDF</strong>
      {!isAnyFileSelected &&
        <div className={fileInputContainerClassName}>
          <FileUpload
            preUploadText="Choose from folder"
            id="cf-file-input"
            fileType=".pdf"
            onChange={handleFileChange}
          />
        </div>
      }
      {isAnyFileSelected &&
        <div className="cf-file-container-selected-container">
          <div className={fileInputContainerClassName} style={{ borderBottom: '1px solid white' }}>
            <div className="cf-file-input-row-element">
              <strong style={{ color: 'black' }}>Selected file</strong>
            </div>
            <div className="cf-file-input-row-element">
              <u><FileUpload
                preUploadText="Change file"
                postUploadText="Change file"
                id="usa-file-input"
                fileType=".pdf"
                onChange={handleFileChange}
              /></u>
            </div>
          </div>
          <div className={fileInputContainerClassName} style={{ borderTop: '1px solid white' }}>
            { selectedFile.fileName }
          </div>
        </div>
      }
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

ErrorsFoundAndCorrectedModal.propTypes = {
  closeModal: PropTypes.func,
  task: PropTypes.shape({
    taskId: PropTypes.string,
    type: PropTypes.string,
  }),
  requestPatch: PropTypes.func,
  appeal: PropTypes.shape({
    veteranFullName: PropTypes.string
  }),
  appealId: PropTypes.string,
  error: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  }),
};

const mapStateToProps = (state, ownProps) => ({
  error: state.ui.messages.error,
  appeal: appealWithDetailSelector(state, ownProps),
  task: taskById(state, { taskId: ownProps.taskId })
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  setAppealAttrs
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(ErrorsFoundAndCorrectedModal));

