import React from 'react';
import PropTypes from 'prop-types';
import { LeverCancelButton } from './LeverCancelButton';
import { LeverSaveButton } from './LeverSaveButton';

const LeverButtonsWrapper = (props) => {
  const { leverStore } = props;

  const cancelButton = <LeverCancelButton leverStore={leverStore} />;
  const saveButton = <LeverSaveButton />;

  return (
    <div className="button-wrapper-styling">
      <div className="cancel-button-styling">{cancelButton}</div>
      <div className="save-button-styling">{saveButton}</div>
    </div>
  );
};

LeverButtonsWrapper.propTypes = {
  leverStore: PropTypes.any
};

export default LeverButtonsWrapper;
