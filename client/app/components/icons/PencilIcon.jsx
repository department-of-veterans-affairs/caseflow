import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

export const PencilIcon = (props) => {
  const { size, color, className } = props;

  return <svg height={size} viewBox="0 0 25 25" version="1.1" className={className}>
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g transform="translate(-729.000000, -307.000000)" fill={color} fillRule="nonzero">
        <g transform="translate(6.000000, 253.000000)">
          <g transform="translate(0.000000, 29.000000)">
            <path d="M738.522827,27 L736.791876,28.7078716 L740.228508,32.0986824
            L741.959459,30.3908108 L738.522827,27 Z M736.216998,29.2750845 L728.503527,36.8857095
            L731.940159,40.2765203 L739.653631,32.6658953 L736.216998,29.2750845 Z M727.979188,37.5027872
            L727,41.76 L731.314743,40.7938682 L727.979188,37.5027872 Z" id="Shape"></path>
          </g>
        </g>
      </g>
    </g>
  </svg>;
};
PencilIcon.propTypes = {

  /**
  Sets height of the component, width is set automatically by the svg viewbox property.
  Default height is 'ICON_SIZES.MEDIUM.
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
PencilIcon.defaultProps = {
  size: ICON_SIZES.MEDIUM,
  color: COLORS.PRIMARY,
  className: ''
};
