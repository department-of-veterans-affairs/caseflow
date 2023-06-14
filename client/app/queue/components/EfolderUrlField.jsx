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

  const efolderLinkRegexMatch = (url) => {
    // could set a second capture group for UUID to ship off to wherever is needed for API call
    return url.match(/https:\/\/vefs-claimevidence.*\.bip\.va\.gov\/file\/\S{8}-\S{4}-\S{4}-\S{4}-\S{12}/) === url.split('?')[0];
  };

  const testDebounce = useCallback(
    debounce(() => {
      console.log("Debounced!");
      if (efolderLinkRegexMatch(value)) {
        // Currently not working ^ need to replace value with the actual value from the input field
        console.log('Valid regex match');
      } else {
        console.log('Invalid efolder regex match');
      }
      // We'll need to dial in this delay a bit.
    }, 500)
  );

  const testOnBlur = () => console.log("Blurred!");
  // implement the regex check in this function as well ^

  return <>
    {/* The UUID in the URL will be the document series ID and not the version ID */}
    <TextField
      label={`Insert Caseflow Reader document hyperlink to request a hearing ${props.requestType}`}
      onChange={testDebounce}
      onBlur={testOnBlur}
      loading
    />
  </>;
};

EfolderUrlField.propTypes = {
  requestType: PropTypes.string
};

export default EfolderUrlField;
