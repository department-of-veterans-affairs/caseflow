import React from 'react';
import PropTypes from 'prop-types';

export const GrayDot = (props) => {
  const { size, color, cname, strokeColor } = props;

  return <svg height={size} viewBox="0 0 25 25" version="1.1">
    <g className={cname} stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g id="750-copy-12" transform="translate(-128.000000, -670.000000)" fill={color} stroke={strokeColor} strokeWidth="4">
        <rect id="Background" x="130" y="672" width="21" height="21" rx="10.5"></rect>
      </g>
    </g>
  </svg>;

};
GrayDot.propTypes = {

  /**
   * Sets height of the component, width is set automatically by the svg viewbox property. Default height is '25px'.
   */
  size: PropTypes.number,

  /**
   * sets color of the component. Default value is '#D6D7D9'.
   */
  color: PropTypes.string,

  /**
   * sets stroke color of the component. Default value is '#ffffff'.
   */
  strokeColor: PropTypes.string,

  /**
   * Adds class to the component. Default value is 'gray-dot'.
   */
  cname: PropTypes.string
};
GrayDot.defaultProps = {
  size: 25,
  color: '#D6D7D9',
  cname: 'gray-dot',
  strokeColor: '#ffffff'
};
