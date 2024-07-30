import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

export const TrashcanIcon = (props) => {
  const { color, size, className, strokeColor } = props;

  return <svg id="trash-can" height={size} viewBox="0 0 24 26" version="1.1"
    xmlns="http://www.w3.org/2000/svg" className={className}>
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g id="Group-7" transform="translate(0.000000, 1.000000)" fill={color}>
        <path d="M14.807412,19.1953107 L14.807412,6.31255183 C14.807412,6.02795378 15.0669633,5.79724147
        15.3871361,5.79724147 C15.7073089,5.79724147 15.9668603,6.02795378 15.9668603,6.31255183
        L15.9668603,19.1953107 C15.9668603,19.4799087 15.7073089,19.710621 15.3871361,19.710621
        C15.0669633,19.710621 14.807412,19.4799087 14.807412,19.1953107 Z" id="Rectangle-4" fill={strokeColor}></path>
        <path d="M11.0147588,19.1953107 L11.0147588,6.31255183 C11.0147588,6.02795378 11.2743101,5.79724147
        11.5944829,5.79724147 C11.9146558,5.79724147 12.1742071,6.02795378 12.1742071,6.31255183
        L12.1742071,19.1953107 C12.1742071,19.4799087 11.9146558,19.710621 11.5944829,19.710621
        C11.2743101,19.710621 11.0147588,19.4799087 11.0147588,19.1953107 Z" id="Rectangle-4-Copy-2"
        fill={strokeColor}></path>
        <path d="M6.98462828,19.1953107 L6.98462828,6.31255183 C6.98462828,6.02795378 7.24417962,5.79724147
        7.56435243,5.79724147 C7.88452524,5.79724147 8.14407658,6.02795378 8.14407658,6.31255183
        L8.14407658,19.1953107 C8.14407658,19.4799087 7.88452524,19.710621 7.56435243,19.710621
        C7.24417962,19.710621 6.98462828,19.4799087 6.98462828,19.1953107 Z" id="Rectangle-4-Copy"
        fill={strokeColor}></path>
        <path d="M22.6301956,3.31935742 L0.558770263,3.31935742 C0.250169968,3.31935742 0,3.00940071
        0,2.62704973 C0,2.24469875 0.250169968,1.93474203 0.558770263,1.93474203 L22.6301956,1.93474203
        C22.9387959,1.93474203 23.1889659,2.24469875 23.1889659,2.62704973 C23.1889659,3.00940071
        22.9387959,3.31935742 22.6301956,3.31935742 Z" id="Rectangle-4-Copy" fill={strokeColor}></path>
        <path d="M4.12058906,23.76869 L18.5286939,23.76869 C19.1332362,23.76869 19.6281771,23.2699141
        19.6457615,22.6429668 L20.199545,2.89862074 L2.31889659,2.89862074 L3.00377093,22.6509241
        C3.02539728,23.2746447 3.51902365,23.76869 4.12058906,23.76869 Z" id="Path-2" stroke={strokeColor}></path>
        <path d="M6.37696562,2.75998994 L6.37696562,1.06644033 C6.37696562,0.477461599 6.88376806,0
        7.50894054,0 L15.6800254,0 C16.3051978,0 16.8120003,0.477461599 16.8120003,1.06644033
        L16.8120003,2.89862074 L6.37696562,2.75998994 Z" id="Path-3" stroke={strokeColor}></path>
      </g>
    </g>
  </svg>;
};
TrashcanIcon.propTypes = {

  /**
  Sets height of the component, width is set automatically by the svg viewbox property.
  Default height is 'ICON_SIZES.MEDIUM'.
  */
  size: PropTypes.number,

  /**
  Sets color of the component. Default value is 'COLORS.WHITE'.
  */
  color: PropTypes.string,

  /**
  Sets stroke color of the component. Default value is 'COLORS.PRIMARY'.
  */

  strokeColor: PropTypes.string,

  /**
  Adds class to the component. Default value is ''.
  */
  className: PropTypes.string
};
TrashcanIcon.defaultProps = {
  size: ICON_SIZES.MEDIUM,
  color: COLORS.WHITE,
  strokeColor: COLORS.PRIMARY,
  className: ''
};
