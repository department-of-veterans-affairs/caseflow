import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

export const RotateIcon = (props) => {
  const { color, size, className } = props;

  return <svg height={size} viewBox="0 0 19 19" xmlns="http://www.w3.org/2000/svg" className={className}>
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g transform="translate(9.313708, 9.313708) rotate(45.000000) translate(-9.313708, -9.313708)
      translate(1.813708, 0.813708)" fillRule="nonzero" fill={color}>
        <path d="M7.57673077,16.3067308 C3.50307692,16.3067308 0.189230769,12.9894231 0.189230769,8.91692308
        C0.189230769,4.84384615 3.50307692,1.52826923 7.57673077,1.52826923 C7.84730769,1.52826923
        8.12076923,1.54384615 8.3925,1.57442308 L8.3925,0.380192308 C8.3925,0.226730769 8.48711538,0.0871153846
        8.62673077,0.0276923077 C8.77211538,-0.0288461538 8.93307692,0.00288461539 9.04384615,0.113076923
        L11.6613462,2.73634615 C11.8101923,2.88519231 11.8101923,3.12288462 11.6613462,3.27403846 L9.045,5.90307692
        C8.93365385,6.01153846 8.77211538,6.045 8.62673077,5.98557692 C8.48711538,5.92557692 8.3925,5.78711538
        8.3925,5.63423077 L8.3925,4.30961538 C8.12192308,4.26 7.84961538,4.2375 7.57673077,4.2375 C4.99615385,4.2375
        2.89615385,6.33692308 2.89615385,8.91692308 C2.89615385,11.4963462 4.99673077,13.5975 7.57673077,13.5975
        C10.1567308,13.5975 12.2561538,11.4957692 12.2561538,8.91692308 C12.2561538,8.7075 12.4263462,8.53615385
        12.6380769,8.53615385 L14.5817308,8.53615385 C14.7923077,8.53615385 14.9636538,8.7075 14.9636538,8.91692308
        C14.9636538,12.9894231 11.6475,16.3067308 7.57673077,16.3067308 Z" id="Shape"></path>
      </g>
    </g>
  </svg>;
};
RotateIcon.propTypes = {

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
  Adds class to the component. Default value is ''.
  */
  className: PropTypes.string
};
RotateIcon.defaultProps = {
  size: ICON_SIZES.MEDIUM,
  color: COLORS.WHITE,
  className: ''
};
