import React from 'react';
import PropTypes from 'prop-types';
import { LeverCancelButton, LeverSaveButton } from './LeverButtons';


const LeverButtonsWrapper = (props) => {
  const { leverStore } = props;

  const cancelButton = <LeverCancelButton leverStore={leverStore} />;
  const saveButton = <LeverSaveButton leverStore={leverStore} />;

  return (
    <div style={{display: "flex"}}>
      <div>{cancelButton}</div>
      <div style={{"margin-left": "auto"}}>{saveButton}</div>
    </div>
  );
};

LeverButtonsWrapper.propTypes = {
  leverStore: PropTypes.any
};

export default LeverButtonsWrapper;
