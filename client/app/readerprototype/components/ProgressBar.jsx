import React from 'react';
import PropTypes from 'prop-types';

const ProgressBar = ({ progressPercentage, loadedBytes, totalBytes, handleCancelRequest }) => {

  return (
    <div
      style={{
        width: '100%',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        padding: '10px',
        backgroundColor: '#F7F7F7',
        borderBottom: '1px solid #DDD',
        position: 'fixed',
        top: 0,
        left: 0,
        zIndex: 1000,
      }}>
      <span style={{ fontSize: '16px', fontWeight: 'bold' }}>Downloading document...</span>
      <div style={{ marginLeft: '10px', textAlign: 'center' }}>
        <span style={{ fontSize: '14px', fontWeight: 'bold' }}>{`${progressPercentage}% downloaded`}</span>
        <br />
        <span style={{ fontSize: '11px' }}>{`${loadedBytes} MB of ${totalBytes} MB`}</span>
      </div>
      <div
        style={{
          width: '200px',
          height: '10px',
          backgroundColor: '#DDD',
          borderRadius: '5px',
          overflow: 'hidden',
          position: 'relative',
          marginLeft: '20px',
        }}
      >
        <div
          style={{
            position: 'absolute',
            left: 0,
            top: 0,
            height: '100%',
            backgroundColor: '#0071bc',
            width: `${progressPercentage}%`,
            transition: 'width 0.5s',
          }}
        />
      </div>
      <div style= {{ display: 'flex', alignItems: 'center' }}>
        <button
          style={{
            backgroundColor: '#0071bc',
            color: '#fff',
            border: 'none',
            padding: '8px 16px',
            borderRadius: '5px',
            cursor: 'pointer',
            marginLeft: '20px',
          }}
          onClick={handleCancelRequest}
        >
          Cancel
        </button>
      </div>
    </div>
  );
};

ProgressBar.propTypes = {
  progressPercentage: PropTypes.number.isRequired,
  loadedBytes: PropTypes.number.isRequired,
  totalBytes: PropTypes.number.isRequired,
  handleCancelRequest: PropTypes.func.isRequired,
};

export default ProgressBar;
