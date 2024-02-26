import React, { useState, useEffect } from 'react';
import Button from 'app/components/Button';
import { useDispatch, useSelector } from 'react-redux';
import SaveModal from './SaveModal';
import { saveLevers } from '../reducers/levers/leversActions';
import { changedLevers, hasChangedLevers, hasNoLeverErrors } from '../reducers/levers/leversSelector';

export const LeverSaveButton = () => {
  const dispatch = useDispatch();
  const theState = useSelector((state) => state);
  const [showModal, setShowModal] = useState(false);
  const [enableSave, setEnableSave] = useState(false);

  useEffect(() => {
    const enable = hasChangedLevers(theState) && hasNoLeverErrors(theState);

    setEnableSave(enable);
    setShowModal(false);
  }, [theState]);

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

export default LeverSaveButton;

