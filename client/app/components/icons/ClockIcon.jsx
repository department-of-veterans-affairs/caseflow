import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

export const ClockIcon = (props) => {
  const { size, color, className } = props;

  return <svg height={size} aria-hidden="true" focusable="false" data-prefix="fas"
    data-icon="clock" className={className} role="img" xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 512 512"><path fill={color}
      d="M256,8C119,8,8,119,8,256S119,504,256,504,504,393,504,256,393,8,256,8Zm92.49,313h0l-20,
  25a16,16,0,0,1-22.49,2.5h0l-67-49.72a40,40,0,0,1-15-31.23V112a16,16,0,0,1,16-16h32a16,
  16,0,0,1,16,16V256l58,42.5A16,16,0,0,1,348.49,321Z"></path></svg>;
};
ClockIcon.propTypes = {

  /**
  Sets height of the component, width is set automatically by the svg viewbox property.
  Default height is 'ICON_SIZES.SMALL'.
  */
  size: PropTypes.number,

  /**
  Sets color of the component. Default value is 'COLORS.BASE'.
  */
  color: PropTypes.string,

  /**
  Adds class to the component. Default value is 'svg-inline--fa fa-clock fa-w-16'.
  */
  className: PropTypes.string
};
ClockIcon.defaultProps = {
  size: ICON_SIZES.SMALL,
  color: COLORS.BASE,
  className: 'svg-inline--fa fa-clock fa-w-16'
};
