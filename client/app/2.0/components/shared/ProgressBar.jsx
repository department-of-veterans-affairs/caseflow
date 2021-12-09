import React from 'react';

const ProgressBar = ({ bgColor, initial }) => {
  const containerStyles = {
    height: 20,
    width: '100%',
    backgroundColor: '#e0e0de',
    marginTop: 50
  };

  const fillerStyles = {
    // transition: 'width 1s ease-in-out',
    height: '100%',
    width: `${initial}%`,
    backgroundColor: bgColor,
    borderRadius: 'inherit',
    textAlign: 'right'
  };

  const labelStyles = {
    padding: 5,
    color: 'white',
    fontWeight: 'bold'
  };

  return (
    <div className="progress-bar-slider">
      <div className="progress-bar-line" />
      <div className="progress-bar-subline progress-bar-inc" />
      <div className="progress-bar-subline progress-bar-dec" />
    </div>
  );
};

export default ProgressBar;
