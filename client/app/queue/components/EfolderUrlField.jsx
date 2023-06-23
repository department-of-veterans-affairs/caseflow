import React, {
  useCallback,
  useState,
  useTransition
} from 'react';
import PropTypes from 'prop-types';
import { debounce } from 'lodash';

import TextField from '../../components/TextField';

// THIS MODAL IS MISSING FUNCTIONALITY THAT CLOSES MODAL WHEN CLICKING OUTSIDE OF MODAL
const EfolderUrlField = (props) => {
  // We can't debounce/compare time of last time of method invocation if the ref changes after
  // a re-render. Thus the need for useCallback.

  const efolderLinkRegexMatch = (url) => {
    // could set a second capture group for UUID to ship off to wherever is needed for API call
    return url.match(/https:\/\/vefs-claimevidence.*\.bip\.va\.gov\/file\/\S{8}-\S{4}-\S{4}-\S{4}-\S{12}/)?.[0] === url.split('?')[0];
  };

  const captureDocumentSeriesId = (url) => {
    return url.match(/\S{8}-\S{4}-\S{4}-\S{4}-\S{12}/)?.[0]
  }

  const testDebounce = useCallback(
    debounce((value) => {
      console.log("Debounced!");
      if (efolderLinkRegexMatch(value)) {
        console.log('Valid regex match');
        const seriesId = captureDocumentSeriesId(value)
        // let seriesIds = VBMSService.fetch_document_series_for(appeal)
        // seriesIds.includes(seriesId)
        // Then render green check since we know this is guaranteed to work
      } else {
        console.log('Invalid efolder regex match');
      }
      // We'll need to dial in this delay a bit.
    }, 500)
  );

  const testOnBlur = (value) => {
    console.log("Blurred!");
    if (efolderLinkRegexMatch(value)) {
      console.log('Valid regex match');
      const seriesId = captureDocumentSeriesId(value)
      // let seriesIds = VBMSService.fetch_document_series_for(appeal)
      // seriesIds.includes(seriesId)
      // Then render green check since we know this is guaranteed to work
    } else {
      console.log('Invalid efolder regex match');
    }
  };

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
