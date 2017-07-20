import React from 'react';
import { loadingSymbolHtml } from './RenderFunctions';


const LoadingScreen = ({ spinnerColor, message }) => {
  return <div
    id="loading-symbol"
    className="cf-app-segment cf-app-segment--alt cf-pdf-center-text">
    {loadingSymbolHtml('', '300px', spinnerColor)}
    <p>{message}</p>
  </div>;
}

export default LoadingScreen;
