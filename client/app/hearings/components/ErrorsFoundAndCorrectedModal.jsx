import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
import Button from '../../components/Button';
import FileUpload from '../../components/FileUpload';
import TextareaField from '../../components/TextareaField';

const ErrorsFoundAndCorrectedModal = (props) => {
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

  const submit = () => {
    // setLoading(true);
    console.log(selectedFile);
    console.log(notes);
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
  closeModal: PropTypes.func
};

export default ErrorsFoundAndCorrectedModal;

