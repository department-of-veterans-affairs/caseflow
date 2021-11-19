import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

export const ClipboardIcon = (props) => {
  const { size, color, className } = props;

  return <svg height={size}
    xmlns="http://www.w3.org/2000/svg" viewBox="0 0 21 21" className={className}>
    <path d="M13.346 2.578h-2.664v-1.29C10.682.585 10.08 0 9.35 0H6.66c-.728 0-1.33.584-1.33
            1.29v1.288H2.663v2.577h10.682V2.578zm-4.02 0H6.66v-1.29h2.665v1.29zm6.685
            3.89V3.234a.665.665 0 0
            0-.678-.656H14v1.29h.68v2.576H6.66v9.046H1.333V3.867h.68v-1.29H.678a.665.665 0 0
            0-.68.657v12.913c0 .365.302.656.68.656h6.006v3.867h9.35l3.996-3.867V6.468h-4.02zm0
            12.378v-2.043h2.112l-2.11 2.043zm2.665-3.356H14.68v3.867H7.992v-11.6h10.682v7.733z"
    fill={color} fillRule="evenodd" /></svg>;
};
ClipboardIcon.propTypes = {

  /**
  Sets height of the component, width is set automatically by the svg viewbox property.
  Default height is 'ICON_SIZES.SMALL'.
  */
  size: PropTypes.number,

  /**
  Sets color of the component. Default value is 'COLORS.GREY'.
  */
  color: PropTypes.string,

  /**
  Adds class to the component. Default value is ''.
  */
  className: PropTypes.string
};
ClipboardIcon.defaultProps = {
  size: ICON_SIZES.SMALL,
  color: COLORS.GREY,
  className: ''
};
