import React from 'react';
import PropTypes from 'prop-types';
import '../../styles/reader/_document_progress_bar.scss';

const DocumentProgressBar = ({ downloadedBytes, totalBytes, onCancel }) => {
  const percentage = totalBytes ? (downloadedBytes / totalBytes) * 100 : 0;

  return (
    <div className="progress-bar-container">
      <div className="progress-bar-text">Downloading document...</div>
      <div className="progress-bar-graphic">
        <div
          className="progress-bar-fill"
          style={{ width: `${percentage}%` }}
        ></div>
      </div>
      <button className="cancel-button" onClick={onCancel}>
        Cancel
      </button>
      <div className="download-text">
        {percentage.toFixed(0)}% downloaded
        <br />
        {(downloadedBytes / 1024 / 1024).toFixed(1)} MB of {(totalBytes / 1024 / 1024).toFixed(1)} MB downloaded
      </div>
    </div>
  );
};

DocumentProgressBar.propTypes = {
  downloadedBytes: PropTypes.number,
  totalBytes: PropTypes.number,
  onCancel: PropTypes.func
};

export default DocumentProgressBar;
