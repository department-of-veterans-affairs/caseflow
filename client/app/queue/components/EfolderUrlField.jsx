import React, {
  useCallback,
  useState,
  useTransition
} from 'react';
import PropTypes from 'prop-types';

import TextField from '../../components/TextField';

const EfolderUrlField = (props) => {

  const extractRequestType = () => (
    props.requestType.replace('Hearing', '').replace('RequestMailTask', '').
      toLowerCase()
  );

  const handleChange = (value) => {
    props?.onChange?.(value);
  };

  return <>
    <TextField
      label={`Include Caseflow Reader document hyperlink to request a hearing ${extractRequestType()}`}
      name="eFolderUrlField"
      value={props.value}
      onChange={handleChange}
      errorMessage={props.errorMessage}
    />
  </>;
};

EfolderUrlField.propTypes = {
  requestType: PropTypes.string,
  value: PropTypes.string,
  errorMessage: PropTypes.string
};

export default EfolderUrlField;
