import React from 'react';
import { css } from 'glamor';

const ProgressBar = ({ downloadedBytes, totalBytes, onCancel, showSideBar }) => {
  const percentage = totalBytes ? (downloadedBytes / totalBytes) * 100 : 0;
  const maxWidth = showSideBar ? 1150 : 900;

  const containerStyle = css({
    display: 'flex',
    alignItems: 'center',
    padding: '30px 20px',
    backgroundColor: '#f5f5f5',
    width: '100%',
    boxSizing: 'border-box',
    [`@media (max-width: ${maxWidth}px)`]: {
      flexDirection: 'column',
      alignItems: 'center',
    }
  });

  const textContainerStyle = css({
    marginRight: '20px',
    whiteSpace: 'nowrap',
    fontSize: '18px',
    fontWeight: 'bold',
    [`@media (max-width: ${maxWidth}px)`]: {
      marginBottom: '10px',
    }
  });

  const progressBarContainerStyle = css({
    flexGrow: 1,
    height: '30px',
    backgroundColor: '#e0e0e0',
    borderRadius: '15px',
    overflow: 'hidden',
    marginRight: '20px',
    display: 'flex',
    alignItems: 'center',
    [`@media (max-width: ${maxWidth}px)`]: {
      display: 'none', // Hide the progress bar graphic on smaller screens
    }
  });

  const progressBarStyle = css({
    height: '100%',
    width: `${percentage}%`,
    backgroundColor: '#007bff',
    transition: 'width 0.5s ease',
  });

  const cancelButtonStyle = css({
    padding: '10px 20px',
    fontSize: '14px',
    color: '#fff',
    backgroundColor: '#007bff',
    border: 'none',
    borderRadius: '5px',
    cursor: 'pointer',
    [`@media (max-width: ${maxWidth}px)`]: {
      marginBottom: '10px',
    }
  });

  const downloadTextStyle = css({
    fontSize: '14px',
    marginTop: '5px',
    [`@media (max-width: ${maxWidth}px)`]: {
      marginTop: '0px',
    }
  });

  return (
    <div {...containerStyle}>
      <div {...textContainerStyle}>Downloading document...</div>
      <div {...progressBarContainerStyle}>
        <div {...progressBarStyle}></div>
      </div>
      <button {...cancelButtonStyle} onClick={onCancel}>
        Cancel
      </button>
      <div {...downloadTextStyle}>
        {percentage.toFixed(0)}% downloaded
        <br />
        {(downloadedBytes / 1024 / 1024).toFixed(1)} MB of {(totalBytes / 1024 / 1024).toFixed(1)} MB downloaded
      </div>
    </div>
  );
};

export default ProgressBar;
