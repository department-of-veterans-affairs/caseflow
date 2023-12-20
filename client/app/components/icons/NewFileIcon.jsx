import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

export const NewFileIcon = (props) => {
  const { size, color, className } = props;

  return <svg height={size} viewBox="0 0 35 11" xmlns="http://www.w3.org/2000/svg" version="1.1" className={className}>
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g id="Group" transform="translate(0.000000, -3.000000)">
        <g id="icon" transform="translate(0.000000, 3.000000)">
          <path d="M0.5,0.5 L0.5,10.5 L8.5,10.5 L8.5,0.5 L0.5,0.5 Z" id="Path" stroke={color}></path>
          <polygon id="Path" fill={color} points="2.25 3 2.25 4 6.75 4 6.75 3"></polygon>
          <polygon id="Path-Copy" fill={color} points="2.25 5 2.25 6 6.75 6 6.75 5"></polygon>
          <polygon id="Path-Copy-2" fill={color} points="2.25 7 2.25 8 6.75 8 6.75 7"></polygon>
        </g>
        <text id="NEW" fontFamily="SourceSansPro-Regular, Source Sans Pro"
          fontSize="13" fontWeight="normal" letterSpacing="-0.75" fill={color}>
          <tspan x="10" y="13">N</tspan>
          <tspan x="17.661" y="13">E</tspan>
          <tspan x="24.512" y="13">W</tspan>
        </text>
      </g>
    </g>
  </svg>;
};
NewFileIcon.propTypes = {

  /**
  Sets height of the component, width is set automatically by the svg viewbox property.
  Default height is 'ICON_SIZES.XSMALL'.
  */
  size: PropTypes.number,

  /**
  Sets color of the component. Default value is 'ICON_COLORS.PURPLE'.
  */
  color: PropTypes.string,

  /**
  Adds class to the component. Default value is ''.
  */
  className: PropTypes.string
};
NewFileIcon.defaultProps = {
  size: ICON_SIZES.XSMALL,
  color: COLORS.PURPLE,
  className: ''
};
