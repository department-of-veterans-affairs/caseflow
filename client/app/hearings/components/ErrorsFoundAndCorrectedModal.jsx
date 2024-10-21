import React, { useState } from 'react';

import Modal from '../../components/Modal';
import Button from '../../components/Button';
import FileUpload from '../../components/FileUpload';

const ErrorsFoundAndCorrectedModal = (props) => {
  const [loading, setLoading] = useState(false);

  const cancel = () => history.goBack();

  const submit = () => {
    setLoading(true);
  };

  const handleFileChange = () => {
    console.log("weee");
  };

  return (
    <Modal
      title="Upload transcript to VBMS"
      closeHandler={cancel}
      confirmButton={<Button disabled={loading} onClick={submit}>Upload to VBMS</Button>}
      cancelButton={<Button linkStyling disabled={loading} onClick={cancel}>Cancel</Button>}
    >
      <p>Please upload the revised transcript file for upload to VBMS.</p>
      <strong style={{ color: 'black' }}>Please select PDF</strong>
      <div className="cf-file-input">
        <div className="cf-txt-c">
          <FileUpload
            preUploadText="Choose from folder"
            postUploadText="Choose a different file"
            id="usa-file-input"
            fileType=".pdf"
            onChange={handleFileChange}
          />
        </div>
      </div>
      <label htmlFor="cf-form-textarea">Please provide context and instructions for this action</label>
      <textarea
        id="cf-form-textarea"
        name="cf-form-textarea"
      >
      </textarea>
    </Modal>
  );
};

export default ErrorsFoundAndCorrectedModal;

