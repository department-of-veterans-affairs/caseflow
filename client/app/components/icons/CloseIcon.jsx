import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

export const CloseIcon = (props) => {
  const { size, color, className } = props;

  return (
    <svg height={size} className={className}
      xmlns="http://www.w3.org/2000/svg" viewBox="0 0 55 55">
      <title>close</title>
      <g fill={color}>
        <path d="M52.6 46.9l-6 6c-.8.8-1.9 1.2-3 1.2s-2.2-.4-3-1.2l-13-13-13 13c-.8.8-1.9 1.2-3
          1.2s-2.2-.4-3-1.2l-6-6c-.8-.8-1.2-1.9-1.2-3s.4-2.2 1.2-3l13-13-13-13c-.8-.8-1.2-1.9-1.2-3s.4-2.2
          1.2-3l6-6c.8-.8 1.9-1.2 3-1.2s2.2.4 3 1.2l13 13 13-13c.8-.8 1.9-1.2 3-1.2s2.2.4 3 1.2l6 6c.8.8
          1.2 1.9 1.2 3s-.4 2.2-1.2 3l-13 13 13 13c.8.8 1.2 1.9 1.2 3s-.4 2.2-1.2 3z" />
      </g>
    </svg>

  );
};
CloseIcon.propTypes = {

  /**
  Sets height of the component, width is set automatically by the svg viewbox property.
  Default height is 'ICON_SIZES.XLARGE'.
  */
  size: PropTypes.number,

  /**
  Sets the color of the component. Default color is 'COLORS.BASE'.
  */
  color: PropTypes.string,

  /**
  Sets the className of the component. Default class is ''.
  */
  className: PropTypes.string,
};
CloseIcon.defaultProps = {
  size: ICON_SIZES.XLARGE,
  color: COLORS.BASE,
  className: 'cf-icon-close'
};
