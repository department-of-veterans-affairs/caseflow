import React from "react";
import PropTypes from 'prop-types';

const LeverAlertBanner = ({ title, message, type }) => {
  const bannerStyle = {
    top: 0,
    left: 0,
    width: "100%",
    zIndex: 9999,
    position: 'absolute',
    margin: 0,
    padding: 0,
    backgroundColor: '',
  };


  return (
    <div style={bannerStyle}>
      <h3>{title}</h3>
      <p>{message}</p>
    </div>
  );
};

LeverAlertBanner.propTypes = {
  title: PropTypes.string.isRequired,
  message: PropTypes.string.isRequired,
  type: PropTypes.oneOf(['success', 'error']),
};

export default LeverAlertBanner;
