import React from 'react';
import PropTypes from 'prop-types';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';

export const SortArrowDown = (props) => {
  const { size, color, cname } = props;

  return <svg height={size} className={cname} viewBox="0 0 16 9" version="1.1" xmlns="http://www.w3.org/2000/svg">
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g fillRule="nonzero" fill={color}>
<<<<<<< HEAD
=======
<<<<<<< HEAD
>>>>>>> 870ec5de027253473c4873180244e197b1cf661c
        <g transform="translate(8.500000, 5.000000) scale(1, -1) translate(-8.500000, -5.000000)
        translate(1.000000, 1.000000)">
          <path d="M14.2222222,0.888888889 C14.2222222,1.12962963 14.1342593,1.33796296 13.9583333,1.51388889
          L7.73611111,7.73611111 C7.56018519,7.91203704 7.35185185,8 7.11111111,8 C6.87037037,8 6.66203704,7.91203704
          6.48611111,7.73611111 L0.263888889,1.51388889 C0.087962963,1.33796296 0,1.12962963 0,0.888888889
          C0,0.648148148 0.087962963,0.439814815 0.263888889,0.263888889 C0.439814815,0.087962963 0.648148148,0
          0.888888889,0 L13.3333333,0 C13.5740741,0 13.7824074,0.087962963 13.9583333,0.263888889
          C14.1342593,0.439814815 14.2222222,0.648148148 14.2222222,0.888888889 Z" id="Shape"></path>
<<<<<<< HEAD
=======
=======
        <g transform="translate(8.500000, 5.000000) scale(1, -1) translate(-8.500000, -5.000000) translate(1.000000, 1.000000)">
          <path d="M14.2222222,0.888888889 C14.2222222,1.12962963 14.1342593,1.33796296 13.9583333,1.51388889 L7.73611111,7.73611111 C7.56018519,7.91203704 7.35185185,8 7.11111111,8 C6.87037037,8 6.66203704,7.91203704 6.48611111,7.73611111 L0.263888889,1.51388889 C0.087962963,1.33796296 0,1.12962963 0,0.888888889 C0,0.648148148 0.087962963,0.439814815 0.263888889,0.263888889 C0.439814815,0.087962963 0.648148148,0 0.888888889,0 L13.3333333,0 C13.5740741,0 13.7824074,0.087962963 13.9583333,0.263888889 C14.1342593,0.439814815 14.2222222,0.648148148 14.2222222,0.888888889 Z" id="Shape"></path>
>>>>>>> da6bfd9a1 (create stories for and reorganize all icons.)
>>>>>>> 870ec5de027253473c4873180244e197b1cf661c
        </g>
      </g>
    </g>
  </svg>;

};
SortArrowDown.propTypes = {

  /**
   * Sets height of the component, width is set automatically by the svg viewbox property. Default height is '10px'.
   */
  size: PropTypes.number,

  /**
     * sets color of the component. Default value is 'COLORS.GREY_DARK'.
     */
  color: PropTypes.string,

  /**
    * Adds class to the component. Default value is 'cf-sort-arrowdown table-icon'.
    */
  cname: PropTypes.string
};
SortArrowDown.defaultProps = {
  size: 17,
  color: COLORS.GREY_DARK,
  cname: 'cf-sort-arrowdown table-icon'
};
