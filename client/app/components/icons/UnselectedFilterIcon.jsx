import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

export const UnselectedFilterIcon = (props) => {
  const { getRef, className, color, strokeColor, size, ...restProps } = props;

  // classnames unselected-filter-icon-border-1 and unselected-filter-icon-inner-1 are used as selectors for tests
  // and do not have any associated CSS rules
  return <svg height={size} viewBox="0 0 21 21" {...restProps}
    ref={getRef} className={`${className} unselected-filter-icon`}>
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g>
        <rect className="unselected-filter-icon-border-1"
          stroke={strokeColor} fill={color} fillRule="nonzero" x="0.5" y="0.5" width="20" height="20" rx="2"></rect>
        <path className="unselected-filter-icon-inner-1"
          d="M16.2335889,6.4 L11.5555083,10.8333333 L11.5555083,14.8333333 C11.5555083,15.0166667
      11.3972274,15.1666667 11.2037729,15.1666667 L9.7968314,15.1666667 C9.60337694,15.1666667
      9.44509602,15.0166667 9.44509602,14.8333333 L9.44509602,10.8333333 L4.76701542,6.4 C4.55597419,6.2
      4.69666834,5.83333333 5.01323019,5.83333333 L15.9697874,5.83333333 C16.303936,5.83333333 16.4446301,6.2
      16.2335889,6.4 Z" fill={strokeColor}></path>
      </g>
    </g>
  </svg>;
};
UnselectedFilterIcon.propTypes = {

  /**
  Sets color of the component. Default value is 'COLORS.WHITE'.
  */
  color: PropTypes.string,

  /**
  Sets stroke color of the component. Default value is 'COLORS.PRIMARY.
  */
  strokeColor: PropTypes.string,

  /**
  Sets height of the component, width is set automatically by the svg viewbox property.
  Default height is 'ICON_SIZES.MEDIUM'.
  */
  size: PropTypes.number,

  /**
  Passes a reference to the component through getRef prop.
  */
  getRef: PropTypes.func,

  /**
  Adds class to the component. Default value is ''.
  */
  className: PropTypes.string

};

UnselectedFilterIcon.defaultProps = {
  color: COLORS.WHITE,
  strokeColor: COLORS.BASE,
  size: ICON_SIZES.MEDIUM,
};
