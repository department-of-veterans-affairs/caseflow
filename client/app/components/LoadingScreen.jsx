import React from 'react';
import { loadingSymbolHtml } from './RenderFunctions';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { css } from 'glamor';

const centerTextStyling = css({
  textAlign: 'center',
  height: '300px',
  marginTop: '75px'
});

const LoadingScreen = ({ spinnerColor, message }) =>
  <AppSegment filledBackground>
    <div {...centerTextStyling}>
      {loadingSymbolHtml('', '150px', spinnerColor)}
      <p>{message}</p>
    </div>
  </AppSegment>;

export default LoadingScreen;
