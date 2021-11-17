import React from 'react';
import { css } from 'glamor';
import { LoadingSymbol } from '../icons/LoadingSymbol';
import PropTypes from 'prop-types';

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

LoadingLabel.propTypes = {
  text: PropTypes.string,
};

export default LoadingLabel;
