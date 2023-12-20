import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

// Not used anywhere

export const SuccessIcon = (props) => {
  const { size, color, className } = props;

  return (
    <svg height={size} className={className}
      xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 50">
      <title>success</title>
      <g fill={color}>
        <path d="M57 13.3L29.9 41.7 24.8 47c-.7.7-1.6 1.1-2.5 1.1-.9 0-1.9-.4-2.5-1.1l-5.1-5.3L1
        27.5c-.7-.7-1-1.7-1-2.7s.4-2 1-2.7l5.1-5.3c.7-.7 1.6-1.1 2.5-1.1.9 0 1.9.4 2.5 1.1l11
        11.6L46.8 2.7c.7-.7 1.6-1.1 2.5-1.1.9 0 1.9.4 2.5 1.1L57 8c.7.7 1 1.7 1 2.7 0 1-.4 1.9-1
        2.6z" />
      </g>
    </svg>
  );
};
SuccessIcon.propTypes = {

  /**
  Sets height of the component, width is set automatically by the svg viewbox property. Default height is '55px'.
  */
  size: PropTypes.number,

  /**
  Sets the color of the component. Default color is green.
  */
  color: PropTypes.string,

  /**
  Sets the className of the component. Default class is empty.
  */
  className: PropTypes.string,
};
SuccessIcon.defaultProps = {
  size: ICON_SIZES.XLARGE,
  color: COLORS.GREEN,
  className: 'cf-icon-found'
};
