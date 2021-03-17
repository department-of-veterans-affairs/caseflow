// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import Alert from 'app/components/Alert';
import { alertStyles } from 'styles/reader/DocumentList/LastRetrievalAlert';
import { formatAlertTime } from 'utils/reader';

/**
 * Last Retrieval Alert Component
 * @param {Object} props -- VBMS Manifest Details
 */
export const LastRetrievalAlert = ({ appeal, manifestVbmsFetchedAt, manifestVvaFetchedAt }) => {
  // Get the formatted times
  const { now, vbmsDiff, vvaDiff } = formatAlertTime(manifestVbmsFetchedAt, manifestVvaFetchedAt);

  return (
    <React.Fragment>
      {(!manifestVbmsFetchedAt || !manifestVvaFetchedAt) && (
        <div {...alertStyles}>
          <Alert title="Error" type="error">
            Some of {appeal.veteran_full_name}'s documents are not available at the moment due to
            a loading error from VBMS or VVA. As a result, you may be viewing a partial list of claims folder documents.
            <br />
            <br />
            Please refresh your browser at a later point to view a complete list of documents in the claims
            folder.
          </Alert>
        </div>
      )}
      {now && (
        <div {...alertStyles}>
          <Alert title="Warning" type="warning">
            We last synced with VBMS and VVA {Math.max(vbmsDiff, vvaDiff)} hours ago. If you'd like to check for new
            documents, refresh the page.
          </Alert>
        </div>
      )}
    </React.Fragment>
  );
};

LastRetrievalAlert.propTypes = {
  manifestVbmsFetchedAt: PropTypes.string,
  manifestVvaFetchedAt: PropTypes.string,
  appeal: PropTypes.object,
};

