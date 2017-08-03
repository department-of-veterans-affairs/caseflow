import React from 'react';
import PropTypes from 'prop-types';
import { loadingSymbolHtml } from './RenderFunctions';

const LoadingMessage = ({ message, spinnerColor }) => (
  <div className="cf-loading-message">
    <div className="loading-message-text">
      <div>{message}</div>
    </div>
    <div className="loading-message-spinner">
      {loadingSymbolHtml('', '100%', spinnerColor)}
    </div>
  </div>
);

LoadingMessage.propTypes = {
  message: PropTypes.string.isRequired,
  spinnerColor: PropTypes.string.isRequired
};

export default LoadingMessage;
