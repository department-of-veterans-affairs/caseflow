import React from 'react';
import PropTypes from 'prop-types';

const ProgressBar = ({ progressPercentage, loadedBytes, totalBytes }) => {

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        marginBottom: '10px',
      }}
    >
      <div
        style={{
          width: '300px',
          height: '10px',
          backgroundColor: '#007bff',
          borderRadius: '5px',
          overflow: 'hidden',
          position: 'relative',
        }}
      >
        <div
          style={{
            position: 'absolute',
            left: 0,
            top: 0,
            height: '100%',
            backgroundColor: '#66d9ef', // Progress bar color
            width: `${progressPercentage}%`,
            transition: 'width 0.5s',
          }}
        />
      </div>
      <div // Display progress text
        style={{
          fontSize: '12px',
          color: '#000',
          marginTop: '5px',
        }}
      >
        {`${progressPercentage}% loaded - ${loadedBytes}/${totalBytes} MB`}
      </div>
    </div>
  );
};

ProgressBar.propTypes = {
  progressPercentage: PropTypes.number.isRequired,
  loadedBytes: PropTypes.number.isRequired,
  totalBytes: PropTypes.number.isRequired,
};

export default ProgressBar;
