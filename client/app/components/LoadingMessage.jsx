import React from 'react';
import PropTypes from 'prop-types';
import { loadingSymbolHtml } from './RenderFunctions';

const LoadingMessage = ({ message, spinnerColor }) => (
  <div>
    <div style={{display: 'inline-block', width: '100%'}}>
      <div style={{display: 'inline-block'}}><div>{message}</div></div> <div style={{width: '30px', display: 'inline-block'}}>{loadingSymbolHtml('', '100%', spinnerColor)}</div>
    </div>
  </div>
);

export default LoadingMessage;
