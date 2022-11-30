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

    if (props.extractedResults?.length > 0) {
      setShowEmptyResultsBanner(false);
      setShowConfirmModal(true);
    }
  }, [props.extractedResults]);

  useEffect(() => {
    if (props.emptyResultsMessage?.length > 0) {
      setShowEmptyResultsBanner(true);
      setShowConfirmModal(false);
    }
  }, [props.emptyResultsMessage]);

  useEffect(() => {
    if (props.manualExtractionSuccess === false) {
      setShowErrorBanner(true);
    } else {
      setShowErrorBanner(false);
    }
  }, [props.manualExtractionSuccess]);

  const onClickGenerate = () => {
    props.sendExtractRequest();
  };

  return (
    <div style={{ height: '75vh' }}>
      {
        showEmptyResultsBanner &&
        <div style={{ padding: '10px' }}>
          <Alert message="No Veterans were found" type="success" />
        </div>
      }
      {
        showErrorBanner &&
        <div style={{ padding: '10px' }}>
          <Alert message="Veteran Extract Failed" type="error" />
        </div>
      }
      {
        !isLoading &&
        <Button
          id="generate-extract"
          onClick={() => onClickGenerate()}
        >
          Generate Veteran Extract
        </Button>
      }
      {
        showConfirmModal &&

        <Modal title="This file contains PII"
          confirmButton={<CSVLink data={extractedResults} filename="veteran_extract.csv" onClick={() => setShowConfirmModal(false)}>Confirm</CSVLink>}
          closeHandler={() => {
            setShowConfirmModal(false);
          }}
        >
          Are you sure you want to download it?
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
  manualExtractionSuccess: PropTypes.bool,
  isLoading: PropTypes.bool,
  sendExtractRequest: PropTypes.func,
  emptyResultsMessage: PropTypes.string,
};

export default GenerateButton;
