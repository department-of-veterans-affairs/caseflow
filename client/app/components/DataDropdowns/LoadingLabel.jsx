import React from 'react';
import { css } from 'glamor';
import { LoadingIcon } from '../icons/LoadingIcon';
import PropTypes from 'prop-types';

const LoadingLabel = ({ text = '' }) => (
  <span {...css({
    '& > *': {
      display: 'inline-block',
      marginRight: '10px'
    }
  })}>
    <LoadingIcon
      text=""
      size={15}
    />
    {text}
  </span>
);

LoadingLabel.propTypes = {
  text: PropTypes.string,
};

export default LoadingLabel;
