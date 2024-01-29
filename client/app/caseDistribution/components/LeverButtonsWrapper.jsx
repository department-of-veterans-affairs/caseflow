import React from 'react';
import { LeverCancelButton } from './LeverCancelButton';
import { LeverSaveButton } from './LeverSaveButton';

const LeverButtonsWrapper = () => {

  const cancelButton = <LeverCancelButton />;
  const saveButton = <LeverSaveButton />;

  return (
    <div className="button-wrapper-styling">
      <div className="cancel-button-styling">{cancelButton}</div>
      <div className="save-button-styling">{saveButton}</div>
    </div>
  );
};

export default LeverButtonsWrapper;
