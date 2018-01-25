import React from 'react';
import { loadingSymbolHtml } from './RenderFunctions';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { css } from 'glamor';

const centerTextStyling = css({
  textAlign: 'center'
});

const LoadingScreen = ({ spinnerColor, message }) => 
  <AppSegment filledBackground>
    <div {...centerTextStyling}>
      {loadingSymbolHtml('', '300px', spinnerColor)}
      <p>{message}</p>
    </div>
  </AppSegment>;

export default LoadingScreen;
