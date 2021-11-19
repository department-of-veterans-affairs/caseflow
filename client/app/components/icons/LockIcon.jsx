import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

export const LockIcon = (props) => {

  const { size, color, className } = props;

  return <svg height={size} viewBox="0 0 18 20" version="1.1"
    xmlns="http://www.w3.org/2000/svg" className={className}>
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g fillRule="nonzero" fill={color}>
        <g id="padlock" transform="translate(2.000000, 1.000000)">
          <path d="M13.6372727,8.06531592 C13.4111091,7.83991791 13.1366667,7.72730348
                      12.8135212,7.72730348 L12.4261455,7.72730348 L12.4261455,5.40900249
                      C12.4261455,3.92797264 11.8933394,2.65631343 10.8273879,1.59381343
                      C9.76152121,0.531271144 8.48590909,0 6.99991515,0 C5.51396364,0 4.23809697,0.531271144
                      3.17231515,1.59377114 C2.10636364,2.65631343 1.57355758,3.92793035 1.57355758,5.40900249
                      L1.57355758,7.72730348 L1.18601212,7.72730348 C0.863121212,7.72730348 0.588509091,7.83991791
                      0.362387879,8.06531592 C0.136266667,8.29054478 0.0232484848,8.56427861
                      0.0232484848,8.88643284 L0.0232484848,15.8408706 C0.0232484848,16.1627289 0.136309091,16.4365473
                      0.362387879,16.6619876 C0.588509091,16.8871741 0.863121212,16.9999154 1.18601212,16.9999154
                      L12.8138182,16.9999154 C13.1369636,16.9999154 13.4113636,16.887301 13.6375697,16.6619876
                      C13.8634788,16.4365473 13.9767091,16.1627289 13.9767091,15.8408706 L13.9767091,8.88630597
                      C13.9768788,8.56440547 13.8634788,8.29071393 13.6372727,8.06531592 Z M10.1006606,7.72730348
                      L3.8991697,7.72730348 L3.8991697,5.40900249 C3.8991697,4.55583085 4.20203636,3.82732587
                      4.80764242,3.22374129 C5.41333333,2.62007214 6.14404848,2.318301 7.00004242,2.318301
                      C7.85612121,2.318301 8.58666667,2.62002985 9.1924,3.22374129 C9.79783636,3.82728358
                      10.1006606,4.55583085 10.1006606,5.40900249 L10.1006606,7.72730348 Z" id="Shape">
          </path>
        </g>
      </g>
    </g>
  </svg>;
};
LockIcon.propTypes = {

  /**
  Sets height of the component, width is set automatically by the svg viewbox property.
  Default height is 'ICON_SIZES.SMALL'.
  */
  size: PropTypes.number,

  /**
  Sets color of the component. Default value is 'COLORS.GREY_DARK'.
  */
  color: PropTypes.string,

  /**
  Adds class to the component. Default value is 'cf-lock-icon'.
  */
  className: PropTypes.string,
};
LockIcon.defaultProps = {
  size: ICON_SIZES.SMALL,
  color: COLORS.GREY_DARK,
  className: 'cf-lock-icon'
};
