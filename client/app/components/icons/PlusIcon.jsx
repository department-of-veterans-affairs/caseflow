import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

export const PlusIcon = (props) => {

  const { color, size, className } = props;

  return <svg height={size} viewBox="0 0 15 15" className={className}>
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g fillRule="nonzero" fill={color}>
        <g>
          <path d="M14.7014925,5.75279851 C14.5026119,5.55391791 14.2609701,5.45451493
          13.9769776,5.45451493 L9.54514925,5.45451493 L9.54514925,1.02276119 C9.54514925,0.73880597
          9.44570896,0.497238806 9.24690299,0.298358209 C9.04802239,0.0994776119 8.80671642,0
          8.52227612,0 L6.47712687,0 C6.1930597,0 5.95156716,0.0993656716 5.75268657,0.298246269
          C5.55380597,0.497126866 5.45440299,0.738656716 5.45440299,1.02264925 L5.45440299,5.45455224
          L1.02268657,5.45455224 C0.738656716,5.45455224 0.497126866,5.55395522 0.298246269,5.75283582
          C0.0993656716,5.95171642 0,6.19302239 0,6.47723881 L0,8.52268657 C0,8.8069403 0.0993283582,9.04828358
          0.298208955,9.2469403 C0.497089552,9.44593284 0.738619403,9.54526119 1.02261194,9.54526119
          L5.45432836,9.54526119 L5.45432836,13.9772388 C5.45432836,14.261194 5.55376866,14.5029851
          5.75264925,14.7017537 C5.95152985,14.9004478 6.19317164,14.9997761 6.47720149,14.9997761
          L8.52238806,14.9997761 C8.80664179,14.9997761 9.04802239,14.9004478 9.2469403,14.7017537
          C9.44589552,14.5028731 9.54522388,14.2612313 9.54522388,13.9772388 L9.54522388,9.54526119
          L13.9769403,9.54526119 C14.261194,9.54526119 14.5026866,9.44593284 14.7014552,9.24697761
          C14.9001493,9.04809701 14.9995896,8.80679104 14.9995896,8.52253731 L14.9995896,6.47701493
          C14.9995896,6.19287313 14.9003358,5.95141791 14.7013433,5.75264925 L14.7014925,5.75279851
          Z" id="Shape"></path>
        </g>
      </g>
    </g>
  </svg>;
};
PlusIcon.propTypes = {

  /**
  Sets the color of the component. Default color is 'COLORS.WHITE'.
  */
  color: PropTypes.string,

  /**
  Sets height of the component, width is set automatically by the svg viewbox property.
  Default height is 'ICON_SIZES.XSMALL'.
  */
  size: PropTypes.number,

  /**
  Sets the class of the component. Default class is ''.
  */
  className: PropTypes.string,
};
PlusIcon.defaultProps = {
  color: COLORS.WHITE,
  size: ICON_SIZES.XSMALL,
  className: ''
};
