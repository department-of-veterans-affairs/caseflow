import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { ACTIONS } from 'app/caseDistribution/reducers/levers/leversActionTypes';
import ApiUtil from '../../util/ApiUtil';
import Button from 'app/components/Button';
import { useDispatch, useSelector } from 'react-redux';
import SaveModal from './SaveModal';

const setShowSuccessBanner = (leverStore) => {
  leverStore.dispatch({
    type: ACTIONS.SHOW_SUCCESS_BANNER,
  });
  setTimeout(() => {
    leverStore.dispatch({
      type: ACTIONS.HIDE_SUCCESS_BANNER,
    });
  }, 10000);
};

const saveLeverChanges = (leverStore) => {
  leverStore.dispatch({
    type: ACTIONS.SAVE_LEVERS,
    saveChangesActivated: true,
  });
};

const showSuccessBanner = (leverStore, shouldShowSuccessBanner) => {
  leverStore.dispatch({
    type: ACTIONS.SHOW_SUCCESS_BANNER,
    showSuccessBanner: shouldShowSuccessBanner,
  });
};

const saveLeversToDB = async (leverStore) => {
  try {
    const leversData = leverStore.getState().levers;

    const postData = {
      current_levers: leversData
    };

    await ApiUtil.post('/case_distribution_levers/update_levers', { data: postData });

    saveLeverChanges(leverStore);
  } catch (error) {
    if (error.response) {
      console.error('Error:', error);
    }
  }
};

export const LeverSaveButton = ({ leverStore }) => {
  const changesOccurred = useSelector((state) => state.caseDistributionLevers.changesOccurred);
  const [showModal, setShowModal] = useState(false);
  const [enableSave, setEnableSave] = useState(false);

  useEffect(() => {
    setEnableSave(changesOccurred);
  }, [changesOccurred]);

  const handleSaveButton = () => {
    setShowModal(true);
  };

  const handleConfirmButton = async () => {
    await saveLeversToDB(leverStore);
    setShowSuccessBanner(leverStore);
    setShowModal(false);
    showSuccessBanner(true);
  };

  return (
    <>
      <Button
        id="LeversSaveButton"
        onClick={handleSaveButton}
        disabled={!enableSave}
      >
        Save
      </Button>
      {showModal &&
        <SaveModal
          setShowModal={setShowModal}
          handleConfirmButton={handleConfirmButton}
        />
      }
    </>
  );
};

LeverSaveButton.propTypes = {
  leverStore: PropTypes.any,
};
