import React from 'react';
import { css } from 'glamor';
import { LoadingSymbol } from '../RenderFunctions';
import PropTypes from 'prop-types';

const LoadingLabel = () => (
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
    {this.props.text}
  </span>
);

LoadingLabel.propTypes = {
  text: PropTypes.string,
};

LoadingLabel.defaultProps = {
  text: ''
};

export default LoadingLabel;
