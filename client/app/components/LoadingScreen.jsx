import React from 'react';
import { loadingSymbolHtml } from './RenderFunctions';
import AppSegment from './AppSegment';
import { css } from 'glamor';

const centerTextStyling = css({
  textAlign: 'center'
});

const LoadingScreen = ({ spinnerColor, message, wrapInAppSegment = true }) => {
  const innerContent = <div {...centerTextStyling}>
    {loadingSymbolHtml('', '300px', spinnerColor)}
    <p>{message}</p>
  </div>;

  return wrapInAppSegment ?
    <AppSegment filledBackground>{innerContent}</AppSegment> :
    innerContent;
};

export default LoadingScreen;
