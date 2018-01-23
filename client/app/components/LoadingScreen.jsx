import React from 'react';
import { loadingSymbolHtml } from './RenderFunctions';
import classNames from 'classnames';

const LoadingScreen = ({ spinnerColor, message, wrapInAppSegment = true }) => {
  const wrapperClassNames = classNames('cf-pdf-center-text', {
    'cf-app-segment cf-app-segment--alt': wrapInAppSegment
  });

  return <div
    className={wrapperClassNames}>
    {loadingSymbolHtml('', '300px', spinnerColor)}
    <p>{message}</p>
  </div>;
};

export default LoadingScreen;
