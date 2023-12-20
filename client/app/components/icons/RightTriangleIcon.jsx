import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

export const RightTriangleIcon = (props) => {
  const { size, color, className } = props;

  return <svg height={size} viewBox="0 0 21 35" className={className}>
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g fillRule="nonzero" fill={color}>
        <g transform="translate(3.000000, 4.000000)">
          <path d="M16,14.2222222 C16,14.7037037 15.8240741,15.1203704 15.4722222,15.4722222
          L3.02777778,27.9166667 C2.67592593,28.2685185 2.25925926,28.4444444 1.77777778,28.4444444
          C1.2962963,28.4444444 0.87962963,28.2685185 0.527777778,27.9166667 C0.175925926,27.5648148
          0,27.1481481 0,26.6666667 L0,1.77777778 C0,1.2962963 0.175925926,0.87962963 0.527777778,0.527777778
          C0.87962963,0.175925926 1.2962963,0 1.77777778,0 C2.25925926,0 2.67592593,0.175925926
          3.02777778,0.527777778 L15.4722222,12.9722222 C15.8240741,13.3240741 16,13.7407407
          16,14.2222222 Z" id="Shape"></path>
        </g>
      </g>
    </g>
  </svg>;
};
RightTriangleIcon.propTypes = {

  /**
  Sets the color of the component. Default color is 'COLORS.BASE'.
  */
  color: PropTypes.string,

  /**
  Sets height of the component, width is set automatically by the svg viewbox property.
  Default height is 'ICON_SIZES.SMALL'.
  */
  size: PropTypes.number,

  /**
  Sets the className of the component. Default className is ''.
  */
  className: PropTypes.string
};
RightTriangleIcon.defaultProps = {
  color: COLORS.BASE,
  size: ICON_SIZES.SMALL,
  className: ''
};
