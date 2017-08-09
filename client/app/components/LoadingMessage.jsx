import React from 'react';
import PropTypes from 'prop-types';

const LoadingMessage = ({ message }) => (
  <div className="cf-loading-message">
    <div className="loading-message-text">
      <div>{message}</div>
    </div>
  </div>
);

LoadingMessage.propTypes = {
  message: PropTypes.string.isRequired
};

export default LoadingMessage;
