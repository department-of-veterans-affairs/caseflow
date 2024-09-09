import React from 'react';
import { LoadingIcon } from '../icons/LoadingIcon';
import PropTypes from 'prop-types';

const LoadingLabel = ({ text = '' }) => (
  <span style={{
    '& > *': {
      display: 'inline-block',
      marginRight: '10px'
    }
  }}>
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
