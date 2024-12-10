import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
import Button from '../../components/Button';
import FileUpload from '../../components/FileUpload';
import TextareaField from '../../components/TextareaField';
import COPY from '../../../COPY';
import { sprintf } from 'sprintf-js';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { requestPatch } from '../uiReducer/uiActions';
import { withRouter } from 'react-router-dom';
import { setAppealAttrs } from '../QueueActions';

import {
  appealWithDetailSelector,
  taskById
} from '../selectors';
import ApiUtil from '../../util/ApiUtil';

const SelectedFileSection = (props) => {
  const { fileInputContainerClassName, handleFileChange, selectedFile } = props;

  return (
    <div className="cf-file-container-selected-container" style={{ marginTop: '2rem', marginBottom: '2rem' }}>
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
  );
};

export const ErrorsFoundAndCorrectedModal = (props) => {
  const [isSubmitDisabled, setIsSubmitDisabled] = useState(true);
  const [loading, setLoading] = useState(false);
  const [isAnyFileSelected, setIsAnyFileSelected] = useState(false);
  const [selectedFile, setSelectedFile] = useState({});
  const [fileInputContainerClassName, setFileInputContainerClassName] = useState('cf-file-input-container');
  const [notes, setNotes] = useState('');
  const [transcriptFileName, setTranscriptFileName] = useState('');
  const [fileNameError, setFileNameError] = useState(false);

  useEffect(() => {
    ApiUtil.get(`/tasks/${props.task.taskId}/uploaded_transcription_file`).then((response) => {
      setTranscriptFileName(response.body.file_name);
    });
  }, []);

  useEffect(() => {
    if (loading) {
      setIsSubmitDisabled(true);
    } else if (fileNameError || notes === '') {
      setIsSubmitDisabled(true);
    } else if (isAnyFileSelected && notes.trim() !== '') {
      setIsSubmitDisabled(false);
    }
  }, [loading, isAnyFileSelected, notes, fileNameError]);

  const cancel = () => {
    props.closeModal();
  };

  const submit = () => {
    // W.I.P.
    // This is where we will send the backend request to upload to VBMS.
    // selectedFile.file contains the base64 encoded string containing the PDF.
    // selectedFile.fileName contains the file's name only.
    //
    // Not sure yet what we're doing with the notes: maybe saving to the ReviewTranscriptTask instructions,
    // in which case we'll need to send props.taskId along with the request.
    const { task, appeal } = props;

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
        }
      };
    };

    const successMsg = {
      title: sprintf(COPY.REVIEW_TRANSCRIPTION_VBMS_MESSAGE, appeal.veteranFullName)
    };

    // setLoading(true);

    return props.requestPatch(`/tasks/${task.taskId}
      /error_found_upload_transcription_to_vbms`, requestParams, successMsg);
  };

  const handleFileChange = (file) => {
    if (file.fileName === transcriptFileName) {
      setFileInputContainerClassName('cf-file-input-container-selected');
      setFileNameError(false);
    } else {
      setFileInputContainerClassName('cf-file-input-container-selected cf-file-error-container');
      setFileNameError(true);
    }
    setIsAnyFileSelected(true);
    setSelectedFile(file);
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
      <p>
        <strong style={{ color: 'black' }}>Transcript file name</strong>
        <div>{transcriptFileName}</div>
      </p>
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
      {fileNameError &&
        <div className="usa-input-error" style={{ right: 0 }}>
          <strong style={{ color: '#cd2026'}}>
            File name must exactly match the transcript file name. Ensure there are no spaces or extra characters.
          </strong>
          <SelectedFileSection
            handleFileChange={handleFileChange}
            fileInputContainerClassName={fileInputContainerClassName}
            selectedFile={selectedFile}
          />
        </div>
      }
      {!fileNameError && isAnyFileSelected &&
        <SelectedFileSection
          handleFileChange={handleFileChange}
          fileInputContainerClassName={fileInputContainerClassName}
          selectedFile={selectedFile}
        />
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

SelectedFileSection.propTypes = {
  handleFileChange: PropTypes.func,
  fileInputContainerClassName: PropTypes.string,
  selectedFile: PropTypes.object
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

