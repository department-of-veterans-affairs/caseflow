// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

/**
 * Last Retrieval Info for Documents Table
 * @param {Object} props -- Contains the last fetched manifest for VVA and VBMS
 */
export const LastRetrievalInfo = ({ manifestVbmsFetchedAt, manifestVvaFetchedAt }) => (
  <React.Fragment>
    {manifestVbmsFetchedAt ? (
      <div id="vbms-manifest-retrieved-at" key="vbms">
          Last VBMS retrieval: {manifestVbmsFetchedAt.slice(0, -5)}
      </div>
    ) : (
      <div className="cf-red-text" key="vbms">
          Unable to display VBMS documents at this time
      </div>
    )}
    {manifestVvaFetchedAt ? (
      <div id="vva-manifest-retrieved-at" key="vva">
          Last VVA retrieval: {manifestVvaFetchedAt.slice(0, -5)}
      </div>
    ) : (
      <div className="cf-red-text" key="vva">
          Unable to display VVA documents at this time
      </div>
    )}
  </React.Fragment>
);

LastRetrievalInfo.propTypes = {
  manifestVbmsFetchedAt: PropTypes.string,
  manifestVvaFetchedAt: PropTypes.string
};
