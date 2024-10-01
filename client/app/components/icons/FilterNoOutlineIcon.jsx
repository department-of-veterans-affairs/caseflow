import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

export const FilterNoOutlineIcon = (props) => {
  const { color, size, className } = props;

  return <svg height={size} viewBox="0 0 12 14" className={className}>
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g fillRule="nonzero" fill={color}>
        <g id="filter-filled-tool-symbol" transform="translate(6.000000, 7.000000)
        scale(-1, 1) translate(-6.000000, -7.000000) translate(0.000000, 1.000000)">
          <path d="M4.55870539,5.67037037 C4.68567635,5.80740741 4.75538589,5.98641975
          4.75538589,6.17160494 L4.75538589,11.6283951 C4.75538589,11.9568025
          5.15497095,12.1234691 5.39148548,11.8925926 L6.92634025,10.1481481
          C7.13173444,9.9037037 7.24501245,9.7827037 7.24501245,9.54074074
          L7.24501245,6.17283951 C7.24501245,5.98765432 7.3159668,5.80864198 7.44169295,5.67159259
          L11.8458299,0.932098765 C12.1757054,0.57654321 11.9217759,0 11.4337967,0
          L0.566576763,0 C0.0786099585,0 -0.176576763,0.575308642 0.154543568,0.932098765
          L4.55870539,5.67037037 Z"></path>
        </g>
      </g>
    </g>
  </svg>;
};
FilterNoOutlineIcon.propTypes = {

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
  Sets the className of the component. Default className is 'filter-icon'.
  */
  className: PropTypes.string
};
FilterNoOutlineIcon.defaultProps = {
  color: COLORS.WHITE,
  size: ICON_SIZES.SMALL,
  className: 'filter-icon'
};
