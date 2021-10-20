import React from 'react';
import { css } from 'glamor';
import { LoadingSymbol } from '../RenderFunctions';

const LoadingLabel = ({ text = '' }) => (
  <span {...css({
    '& > *': {
      display: 'inline-block',
      marginRight: '10px'
    }
  })}>
    <LoadingSymbol
      text=""
      size="15px"
    />
    {text}
  </span>
);

export default LoadingLabel;
