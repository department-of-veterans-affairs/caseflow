/* eslint-disable max-len */
import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

export const GrayDotIcon = (props) => {
  const { size, color, className, strokeColor } = props;

  return <svg height={size} viewBox="0 0 25 25" version="1.1" role="img" className={className} aria-labelledby="gray-dot-title">
    <title id="gray-dot-title">Gray dot: Pending</title>
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g id="750-copy-12" transform="translate(-128.000000, -670.000000)"
        fill={color} stroke={strokeColor} strokeWidth="4">
        <rect id="Background" x="130" y="672" width="21" height="21" rx="10.5"></rect>
      </g>
    </g>
  </svg>;

};
GrayDotIcon.propTypes = {

  /**
  Sets height of the component, width is set automatically by the svg viewbox property.
  Default height is 'ICON_SIZES.MEDIUM'.
  */
  size: PropTypes.number,

  /**
  Sets color of the component. Default value is 'COLORS.GREY_LIGHT'.
  */
  color: PropTypes.string,

  /**
  Sets stroke color of the component. Default value is 'COLORS.WHITE'.
  */
  strokeColor: PropTypes.string,

  /**
  Adds class to the component. Default value is 'gray-dot'.
  */
  className: PropTypes.string
};
GrayDotIcon.defaultProps = {
  size: ICON_SIZES.MEDIUM,
  color: COLORS.GREY_LIGHT,
  className: 'gray-dot',
  strokeColor: COLORS.WHITE
};
