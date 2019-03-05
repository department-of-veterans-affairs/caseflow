import React from 'react';
import { css } from 'glamor';
import { loadingSymbolHtml } from '../RenderFunctions';

const LoadingLabel = ({ text = '' }) => (
  <span {...css({
    '& > *': {
      display: 'inline-block',
      marginRight: '10px'
    }
  })}>
    {loadingSymbolHtml('', '15px')}
    {text}
  </span>
);

export default LoadingLabel;
