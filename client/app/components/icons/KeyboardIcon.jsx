import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

export const KeyboardIcon = (props) => {
  const { size, color, className } = props;

  return <svg height={size} viewBox="0 0 23 17" version="1.1" xmlns="http://www.w3.org/2000/svg" className={className}>
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g id="keyboard" fillRule="nonzero" fill={color}>
        <path d="M20.9986,1 L1.4014,1 C0.6272,1 0,1.6384 0,2.393 L0,13.607 C0,14.377 0.6216,15
        1.4014,15 L20.9986,15 C21.7728,15 22.4,14.3616 22.4,13.607 L22.4,2.393 C22.4,1.623 21.7784,1
        20.9986,1 Z M16.8,3.8 L18.2,3.8 L18.2,5.2 L16.8,5.2 L16.8,3.8 Z M16.8,6.6 L18.2,6.6 L18.2,8 L16.8,8
        L16.8,6.6 Z M14,3.8 L15.4,3.8 L15.4,5.2 L14,5.2 L14,3.8 Z M14,6.6 L15.4,6.6 L15.4,8 L14,8 L14,6.6 Z
        M11.2,3.8 L12.6,3.8 L12.6,5.2 L11.2,5.2 L11.2,3.8 Z M14,9.4 L14,10.8 L12.6,10.8 L12.6,9.4 L14,9.4 Z
        M11.2,6.6 L12.6,6.6 L12.6,8 L11.2,8 L11.2,6.6 Z M8.4,3.8 L9.8,3.8 L9.8,5.2 L8.4,5.2 L8.4,3.8 Z
        M11.2,9.4 L11.2,10.8 L9.8,10.8 L9.8,9.4 L11.2,9.4 Z M8.4,6.6 L9.8,6.6 L9.8,8 L8.4,8 L8.4,6.6 Z
        M5.6,3.8 L7,3.8 L7,5.2 L5.6,5.2 L5.6,3.8 Z M8.4,9.4 L8.4,10.8 L7,10.8 L7,9.4 L8.4,9.4 Z M1.4,3.8
        L4.2,3.8 L4.2,5.2 L1.4,5.2 L1.4,3.8 Z M1.4,6.6 L4.2,6.6 L4.2,8 L1.4,8 L1.4,6.6 Z M2.8,13.6
        L1.4,13.6 L1.4,12.2 L2.8,12.2 L2.8,13.6 Z M2.8,10.8 L1.4,10.8 L1.4,9.4 L2.8,9.4 L2.8,10.8 Z
        M5.6,13.6 L4.2,13.6 L4.2,12.2 L5.6,12.2 L5.6,13.6 Z M5.6,10.8 L4.2,10.8 L4.2,9.4 L5.6,9.4
        L5.6,10.8 Z M5.6,6.6 L7,6.6 L7,8 L5.6,8 L5.6,6.6 Z M15.4,13.6 L7,13.6 L7,12.2 L15.4,12.2
        L15.4,13.6 Z M15.4,9.4 L16.8,9.4 L16.8,10.8 L15.4,10.8 L15.4,9.4 Z M18.2,13.6 L16.8,13.6
        L16.8,12.2 L18.2,12.2 L18.2,13.6 Z M21,13.6 L19.6,13.6 L19.6,12.2 L21,12.2 L21,13.6 Z
        M21,10.8 L18.2,10.8 L18.2,9.4 L21,9.4 L21,10.8 Z M21,8 L19.6,8 L19.6,5.2 L21,5.2 L21,8 Z"
        id="Shape"></path>
      </g>
    </g>
  </svg>;

};
KeyboardIcon.propTypes = {

  /**
  Sets height of the component, width is set automatically by the svg viewbox property.
  Default height is 'ICON_SIZES.SMALL'.
  */
  size: PropTypes.number,

  /**
  Sets color of the component. Default value is 'COLORS.PRIMARY'.
  */
  color: PropTypes.string,

  /**
  Adds class to the component. Default value is ''.
  */
  className: PropTypes.string
};
KeyboardIcon.defaultProps = {
  size: ICON_SIZES.SMALL,
  color: COLORS.PRIMARY,
  className: ''
};
