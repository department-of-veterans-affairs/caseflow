/* eslint-disable func-style */
import React, { useState } from 'react';
import Button from '../../components/Button';
import Modal from '../../components/Modal';
import Alert from '../../components/Alert';
import LoadingContainer from '../../components/LoadingContainer';
import { LOGO_COLORS } from 'app/constants/AppConstants';
import { sendExtractRequest } from '../actions';

function GenerateButton(...btnProps) {

  // state properties
  const [modal, setModal] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [showBanner, setShowBanner] = useState(false);
  const [showErrorBanner, setShowErrorBanner] = useState(false);
  const [extractedResults, setExtractedResults] = useState('');


  const onClickGenerate = async () => {
    const res = await sendExtractRequest();
    console.log(res);
    //setExtractedResults(res);

    //if res is error
    //show error banner

    //if res is empty
    //showBanner

    //if res is not empty
    //show modal



  };

  const onClickConfirmation = () => {
    setModal(false);
    setIsLoading(true);



    request.onreadystatechange = () => {
      if (request.readyState === 4 && request.status === 200) {
        const downloadLink = document.createElement("a");
        const blob = new Blob(["\ufeff", request.response]);
        const url = URL.createObjectURL(blob);
        downloadLink.href = url;
        downloadLink.download = "data.csv";

        document.body.appendChild(downloadLink);
        downloadLink.click();
        document.body.removeChild(downloadLink);

        // stop loading
        setIsLoading(false);
        setShowBanner(true);
      } else if (request.readyState === 4 && (request.status < 200 || request.status >= 300)) {
        // stop loading
        setIsLoading(false);
        setShowErrorBanner(true);
      }
    };
  }

  return (
    <div style={{ height: '75vh' }}>
      {
        showBanner &&
        <div style={{ padding: '10px' }}>
          <Alert message="download success" type="success" />
        </div>
      }
      {
        showErrorBanner &&
        <div style={{ padding: '10px' }}>
          <Alert message="download failed" type="error" />
        </div>
      }
      {
        !isLoading &&
        <Button
          id="generate-extract"
          onClick={() => onClickGenerate()}
          {...btnProps}
        >
          Generate
        </Button>
      }
      {
        modal &&

        <Modal title="The file contains PII information, click OK to proceed"
          confirmButton={<Button onClick={() => { onClickConfirmation() }}>Okay</Button>}
          closeHandler={() => { setModal(false); }}
        >
          Whenever you are click on Okay button then file will start downloading.
        </Modal>
      }
      {
        isLoading &&

        <LoadingContainer color={LOGO_COLORS.QUEUE.ACCENT}>
          <div className="loading-div">
            Action is Running...
          </div>
        </LoadingContainer>
      }
    </div>
  );
}

GenerateButton.propTypes = {
};

export default GenerateButton;
