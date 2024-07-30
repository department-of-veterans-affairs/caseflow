import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

export const DownloadIcon = (props) => {
  const { size, color, className } = props;

  return <svg height={size} viewBox="0 0 14 19" version="1.1" xmlns="http://www.w3.org/2000/svg" className={className}>
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g fill={color}>
        <path d="M14,15.6826233 C14,15.1556346 13.5724432,14.7280778 13.0454545,14.7280778
        L9.90909091,14.7280778 L6.09090909,14.7280778 L1.95454545,14.7280778
        C1.42755682,14.7280778 1,15.1556346 1,15.6826233 L1,16.454385 C1,16.9813736
        1.42755682,17.4089304 1.95454545,17.4089304 L6.09090909,17.4089304
        L9.90909091,17.4089304 L13.0454545,17.4089304 C13.5724432,17.4089304
        14,16.9813736 14,16.454385 L14,15.6826233 Z" id="Expand"></path>
        <g transform="translate(7.362992, 6.091070) rotate(134.000000)
        translate(-7.362992, -6.091070) translate(2.862992, 1.591070)">
          <path d="M7.97587683,5.70725389 C7.89258963,5.73878036 7.81210001,5.75456018
          7.73525063,5.75456018 C7.5622047,5.75456018 7.41780876,5.69452395
          7.30223134,5.57474986 L5.91658308,4.21185126 L2.03071117,8.0340371
          C1.90866222,8.15384435 1.76443481,8.21388058 1.59759076,8.21388058
          C1.4306793,8.21388058 1.28631706,8.15384435 1.16443664,8.0340371
          L0.182888043,7.06848485 C0.0609739162,6.9488102 -3.27418093e-11,6.80655982 -3.27418093e-11,6.64259561
          C-3.27418093e-11,6.47869771 0.0609739162,6.33664623 0.182888043,6.21683898
          L4.06906331,2.39458684 L2.68331394,1.03168824 C2.4843819,0.848695439 2.43951939,0.627976942
          2.54852417,0.369168095 C2.65752895,0.123155484 2.84688852,9.50350909e-14
          3.11633323,9.50350909e-14 L7.73528434,9.50350909e-14 C7.90206098,9.50350909e-14
          8.04645692,0.0600030758 8.16853957,0.179942926 C8.29031888,0.299750172
          8.35125909,0.441768502 8.35125909,0.605832161 L8.35125909,5.14886062
          C8.35122538,5.41386868 8.22594067,5.59991137 7.97587683,5.70725389 Z" id="Path"></path>
        </g>
      </g>
    </g>
  </svg>;
};
DownloadIcon.propTypes = {

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
DownloadIcon.defaultProps = {
  size: ICON_SIZES.MEDIUM,
  color: COLORS.WHITE,
  className: ''
};
