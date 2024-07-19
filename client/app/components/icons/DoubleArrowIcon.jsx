import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

export const DoubleArrowIcon = (props) => {
  const { topColor, bottomColor, size, className } = props;

  return <svg height={size} className={className} viewBox="0 0 13 16" version="1.1" xmlns="http://www.w3.org/2000/svg">
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g fillRule="nonzero">
        <g fill={topColor} transform="translate(2.000000, 1.000000)" data-testid="topColorGroup">
          <g transform="translate(5.000000, 2.666667) scale(-1, 1)
          rotate(-180.000000) translate(-5.000000, -2.666667) ">
            <path d="M9.48148147,0.592592593 C9.48148147,0.75308642 9.42283953,0.891975307
            9.30555553,1.00925926 L5.15740741,5.15740741 C5.04012346,5.27469136
            4.90123457,5.33333333 4.74074074,5.33333333 C4.58024691,5.33333333
            4.44135803,5.27469136 4.32407407,5.15740741 L0.175925926,1.00925926
            C0.0586419753,0.891975307 0,0.75308642 0,0.592592593 C0,0.432098765
            0.0586419753,0.293209877 0.175925926,0.175925926 C0.293209877,0.0586419753
            0.432098765,0 0.592592593,0 L8.88888887,0 C9.04938273,0 9.1882716,0.0586419753
            9.30555553,0.175925926 C9.42283953,0.293209877 9.48148147,0.432098765
            9.48148147,0.592592593 Z"></path>
          </g>
        </g>
        <g fill={bottomColor} transform="translate(7.000000, 11.666667) scale(1, -1)
        translate(-7.000000, -11.666667) translate(2.000000, 9.000000)" data-testid="bottomColorGroup">
          <g transform="translate(5.000000, 2.666667) scale(-1, 1)
          rotate(-180.000000) translate(-5.000000, -2.666667) ">
            <path d="M9.48148147,0.592592593 C9.48148147,0.75308642
            9.42283953,0.891975307 9.30555553,1.00925926 L5.15740741,5.15740741
            C5.04012346,5.27469136 4.90123457,5.33333333 4.74074074,5.33333333
            C4.58024691,5.33333333 4.44135803,5.27469136 4.32407407,5.15740741
            L0.175925926,1.00925926 C0.0586419753,0.891975307 0,0.75308642 0,0.592592593
            C0,0.432098765 0.0586419753,0.293209877 0.175925926,0.175925926 C0.293209877,0.0586419753
            0.432098765,0 0.592592593,0 L8.88888887,0 C9.04938273,0 9.1882716,0.0586419753
            9.30555553,0.175925926 C9.42283953,0.293209877 9.48148147,0.432098765
            9.48148147,0.592592593 Z"></path>
          </g>
        </g>
      </g>
    </g>
  </svg>;
};
DoubleArrowIcon.propTypes = {

  /**
  Sets the top arrow color. Defauly color is 'COLORS.GREY_DARK'.
  */
  topColor: PropTypes.string,

  /**
  Sets the bottom arrow color. Defauly color is 'COLORS.GREY_DARK'.
  */
  bottomColor: PropTypes.string,

  /**
  Sets height of the component, width is set automatically by the svg viewbox property.
  Default height is 'ICON_SIZES.SMALL'.
  */
  size: PropTypes.number,

  /**
  Adds class to the component. Default value is 'table-icon'.
  */
  className: PropTypes.string
};
DoubleArrowIcon.defaultProps = {
  topColor: COLORS.GREY_DARK,
  bottomColor: COLORS.GREY_DARK,
  size: ICON_SIZES.SMALL,
  className: 'table-icon'
};
