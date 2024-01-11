import React, { useState, useEffect } from 'react';
import Button from 'app/components/Button';
import { useDispatch, useSelector } from 'react-redux';
import SaveModal from './SaveModal';
import { saveLevers } from '../reducers/levers/leversActions';
import { changedLevers, getLevers, hasChangedLevers } from '../reducers/levers/leversSelector';

export const LeverSaveButton = () => {
  const dispatch = useDispatch();
  const theState = useSelector((state) => state);
  const levers = getLevers(theState);
  const [showModal, setShowModal] = useState(false);
  const [enableSave, setEnableSave] = useState(false);

  useEffect(() => {
    const enable = hasChangedLevers(theState);

    setEnableSave(enable);

    if (!enable) {
      setShowModal(false);
    }
  }, [levers]);

  const handleSaveButton = () => {
    setShowModal(true);
  };

  const handleConfirmButton = () => {
    const updatedLevers = changedLevers(theState);

    dispatch(saveLevers(updatedLevers));
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

