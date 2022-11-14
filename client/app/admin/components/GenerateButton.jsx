/* eslint-disable func-style */
import React, { useEffect, useState } from 'react';
import Button from '../../components/Button';
import Modal from '../../components/Modal';
import Alert from '../../components/Alert';
import LoadingContainer from '../../components/LoadingContainer';
import { LOGO_COLORS } from 'app/constants/AppConstants';
import PropTypes from 'prop-types';
import { CSVLink } from 'react-csv';

const GenerateButton = (props) => {

  // state properties
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [showEmptyResultsBanner, setShowEmptyResultsBanner] = useState(false);
  const [showErrorBanner, setShowErrorBanner] = useState(false);
  const [extractedResults, setExtractedResults] = useState('');

  useEffect(() => {
    setIsLoading(props.isLoading);
  }, [props.isLoading]);

  useEffect(() => {
    setExtractedResults(props.extractedResults);
    console.log(props);
    // if (extractedResults.length > 0) {
    //   setShowConfirmModal(true);
    // }
    // else {
    //   setShowEmptyResultsBanner(true);
    // }
  }, [props.extractedResults]);

  const onClickGenerate = () => {
    props.sendExtractRequest();
  };

  return (
    <div style={{ height: '75vh' }}>
      {
        showEmptyResultsBanner &&
        <div style={{ padding: '10px' }}>
          <Alert message="No Veterans were found." type="success" />
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
        >
          Generate
        </Button>
      }
      {
        showConfirmModal &&

        <Modal title="The file contains PII information, click OK to proceed"
          confirmButton={<CSVLink data={extractedResults} filename="TestDownload.csv">Download</CSVLink>}
          closeHandler={() => {
            setShowConfirmModal(false);
          }}
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
};

GenerateButton.propTypes = {
  extractedResults: PropTypes.string,
  isLoading: PropTypes.bool,
  sendExtractRequest: PropTypes.func,
};

export default GenerateButton;
