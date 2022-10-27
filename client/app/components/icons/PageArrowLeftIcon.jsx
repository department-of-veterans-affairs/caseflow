import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

export const PageArrowLeftIcon = (props) => {
  const { color, size, className } = props;

  return <svg height={size} viewBox="0 0 17 17" version="1.1" xmlns="http://www.w3.org/2000/svg" className={className}>
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g transform="translate(-1.000000, -1.000000)" fillRule="nonzero" fill={color}>
        <g transform="translate(9.500000, 9.500000) scale(-1, 1) translate(-9.500000, -9.500000)
        translate(1.000000, 1.000000)">
          <path d="M16.5548504,7.51484045 L9.04961283,0.414417978 C8.75778622,0.138101124
          8.40789311,0 8.00053919,0 C7.60077672,0 7.254962,0.138101124 6.96289311,0.414417978
          L6.09831591,1.23240449 C5.80620665,1.49420449 5.6601924,1.82140674 5.6601924,2.21408764
          C5.6601924,2.60669213 5.80620665,2.93389438 6.09831591,3.19577079 L9.47622803,6.40235281
          L1.35987886,6.40235281 C0.96031829,6.40235281 0.635581948,6.53865843 0.385790974,6.81138427
          C0.136,7.08411011 0.0111045131,7.41314607 0.0111045131,7.79841573 L0.0111045131,9.19455506
          C0.0111045131,9.57993933 0.13604038,9.90886067 0.385790974,10.1815865 C0.635541568,10.4543124
          0.96031829,10.5905034 1.35987886,10.5905034 L9.47606651,10.5905034 L6.09819477,13.786427
          C5.80608551,14.0625528 5.66007126,14.3934607 5.66007126,14.7789596 C5.66007126,15.164382
          5.80608551,15.4952517 6.09819477,15.7713775 L6.96277197,16.589364 C7.2626342,16.8584225
          7.60844893,16.9929326 8.00041805,16.9929326 C8.40014014,16.9929326 8.74995249,16.8584225
          9.04953207,16.589364 L16.5547292,9.48894157 C16.8391259,9.21988315 16.9814252,8.88912809
          16.9814252,8.49640899 C16.9814252,8.09654607 16.8391259,7.76919101 16.5548504,7.51484045 Z"></path>
        </g>
      </g>
    </g>
  </svg>;
};
PageArrowLeftIcon.propTypes = {

  /**
  Sets the color of the component. Default color is 'COLORS.WHITE'.
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
PageArrowLeftIcon.defaultProps = {
  color: COLORS.WHITE,
  size: ICON_SIZES.SMALL,
  className: ''
};
