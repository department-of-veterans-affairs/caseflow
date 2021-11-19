import React from 'react';
import PropTypes from 'prop-types';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { ICON_SIZES } from '../../constants/AppConstants';

export const ArrowDownIcon = (props) => {
  const { size, color, className } = props;

  return <svg height={size} viewBox="0 0 16 17" version="1.1" xmlns="http://www.w3.org/2000/svg" className={className}>
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g id="arrow-down-323A45" fillRule="nonzero" fill={color}>
        <path d="M14.1993267,7.10067326 C14.0081866,6.8760755 13.7599514,6.76382382 13.4543434,6.76382382
        L7.24797043,6.76382382 L9.83104882,4.13201258 C10.0544265,3.90458337 10.1660227,3.63207101 10.1660227,3.31463281
        C10.1660227,2.99735191 10.0544574,2.72483955 9.83104882,2.49731595 L9.16983979,1.83258337 C8.94655476,1.60515416
        8.68204644,1.49129798 8.37643837,1.49129798 C8.06490155,1.49129798 7.79739799,1.60502831 7.57417471,1.83258337
        L1.8349063,7.67105528 C1.61742649,7.90458786 1.50870202,8.17706876 1.50870202,8.48843505 C1.50870202,8.8058418
        1.61742649,9.07530247 1.8349063,9.29675416 L7.57417471,15.1532216 C7.80335761,15.3747991 8.07079941,15.4856665
        8.37643837,15.4856665 C8.68785167,15.4856665 8.9523291,15.3747991 9.16980891,15.1532216 L9.83101794,14.4707452
        C10.0543956,14.2552081 10.1659918,13.9856216 10.1659918,13.6624261 C10.1659918,13.3388845 10.0544265,13.069298
        9.83101794,12.8538867 L7.24793955,10.2131092 L13.4543125,10.2131092 C13.7598897,10.2131092 14.0081557,10.1008261
        14.1992958,9.87625977 C14.3902507,9.65166202 14.4856664,9.38078562 14.4856664,9.06337887 L14.4856664,7.91364854
        C14.4857899,7.5962418 14.3902507,7.32527101 14.1993267,7.10067326 Z" id="Shape" transform="translate(7.997184,
        8.488482) rotate(270.000000) translate(-7.997184, -8.488482) "></path>
      </g>
    </g>
  </svg>;
};
ArrowDownIcon.propTypes = {

  /**
  Sets height of the component, width is set automatically by the svg viewbox property.
  Default height is 'ICON_SIZES.SMALL'.
  */
  size: PropTypes.number,

  /**
  Sets color of the component. Default value is 'COLORS.GREY_MEDIUM'.
  */
  color: PropTypes.string,

  /**
  Adds class to the component. Default value is ''.
  */
  className: PropTypes.string
};
ArrowDownIcon.defaultProps = {
  size: ICON_SIZES.SMALL,
  color: COLORS.GREY_DARK,
  className: ''
};
