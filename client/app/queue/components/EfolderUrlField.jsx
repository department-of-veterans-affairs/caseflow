import React, {
  useCallback,
  useState,
  useTransition
} from 'react';
import PropTypes from 'prop-types';
import { debounce } from 'lodash';

import TextField from '../../components/TextField';

const EfolderUrlField = (props) => {
  // We can't debounce/compare time of last time of method invocation if the ref changes after
  // a re-render. Thus the need for useCallback.
  const testDebounce = useCallback(
    debounce(() => {
      console.log("Debounced!");

      // We'll need to dial in this delay a bit.
    }, 500)
  );

  const testOnBlur = () => console.log("Blurred!");

  return <>
    <TextField
      label={`Insert Caseflow Reader document hyperlink to request a hearing ${props.requestType}`}
      onChange={testDebounce}
      onBlur={testOnBlur}
    />
  </>;
};

EfolderUrlField.propTypes = {
  requestType: PropTypes.string
};

export default EfolderUrlField;
