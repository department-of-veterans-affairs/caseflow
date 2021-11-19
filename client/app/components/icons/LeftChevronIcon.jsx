import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

export const LeftChevronIcon = (props) => {
  const { size, color, className } = props;

  return <svg height={size} className={className} viewBox="0 0 11 17" version="1.1" xmlns="http://www.w3.org/2000/svg">
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g id="chevron-left-white" fillRule="nonzero" fill={color}>
        <path d="M10.148056,7.63345458 L3.83667957,1.36581253 C3.60425101,1.12190379 3.31401199,1
        2.9653861,1 C2.6167602,1 2.32652118,1.12203868 2.09409262,1.36581253 L1.35839094,2.08799554
        C1.11955406,2.32549717 1.00013563,2.61418827 1.00013563,2.95437235 C1.00013563,3.28811559
        1.11952016,3.5802463 1.35839094,3.83049472 L6.06300954,8.50003372 L1.3581875,13.1791834
        C1.11941844,13.416685 1,13.7053761 1,14.0455939 C1,14.3793034 1.11938453,14.6715353
        1.3581875,14.9216826 L2.09395699,15.6437644 C2.33275996,15.881266 2.62330414,16 2.96525047,16
        C3.30733242,16 3.59780879,15.881266 3.83654395,15.6437644 L10.148056,9.37612237 C10.3869607,9.12580651
        10.5064808,8.83374324 10.5064808,8.5 C10.5065147,8.15981592 10.3869607,7.87095621 10.148056,7.63345458 Z"
        id="Shape" transform="translate(5.753240, 8.500000) scale(-1, 1) translate(-5.753240, -8.500000) "></path>
      </g>
    </g>
  </svg>;
};
LeftChevronIcon.propTypes = {

  /**
  Sets height of the component, width is set automatically by the svg viewbox property.
  Default height is 'ICON_SIZES.SMALL'.
  */
  size: PropTypes.number,

  /**
  Sets color of the component. Default value is 'COLORS.GREY_MEDIUM'.
  */
  color: PropTypes.string,

  /**
  Adds class to the component. Default value is ''.
  */
  className: PropTypes.string
};
LeftChevronIcon.defaultProps = {
  size: ICON_SIZES.SMALL,
  color: COLORS.WHITE,
  className: 'fa-chevron-left'
};
