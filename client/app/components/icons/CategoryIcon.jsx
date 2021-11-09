import React from 'react';
import PropTypes from 'prop-types';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';

export const CategoryIcon = (props) => {
  const { color, size, cname } = props;

  return <svg height={size} viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg" className={cname}>
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g fill={color}>
<<<<<<< HEAD
=======
<<<<<<< HEAD
>>>>>>> 870ec5de027253473c4873180244e197b1cf661c
        <path d="M4.64092309,1 C3.21738445,1 2,2.16989858 2,3.68789356 L2,17.9336416 C2,18.2762127
        2.06871806,18.7149247 2.37159862,19.0431298 C2.67415351,19.371335 3.04184399,19.4258517
        3.32062438,19.4258517 C3.47694983,19.4229048 3.62839011,19.3683882 3.75800997,19.2674586
        L10.4497163,14.2184033 L17.1414226,19.2674586 C17.2700654,19.3683882 17.4215057,19.4229048
        17.5791339,19.4258517 C17.8575886,19.4258517 18.2252791,19.371335 18.5268569,19.0431298
        C18.8297375,18.7149247 18.8984556,18.2762127 18.8984556,17.9336416 L18.8984556,3.68789356
        C18.8984556,2.16989858 17.6820481,1 16.2585095,1 L4.64092309,1 Z"></path>
<<<<<<< HEAD
=======
=======
        <path d="M4.64092309,1 C3.21738445,1 2,2.16989858 2,3.68789356 L2,17.9336416 C2,18.2762127 2.06871806,18.7149247 2.37159862,19.0431298 C2.67415351,19.371335 3.04184399,19.4258517 3.32062438,19.4258517 C3.47694983,19.4229048 3.62839011,19.3683882 3.75800997,19.2674586 L10.4497163,14.2184033 L17.1414226,19.2674586 C17.2700654,19.3683882 17.4215057,19.4229048 17.5791339,19.4258517 C17.8575886,19.4258517 18.2252791,19.371335 18.5268569,19.0431298 C18.8297375,18.7149247 18.8984556,18.2762127 18.8984556,17.9336416 L18.8984556,3.68789356 C18.8984556,2.16989858 17.6820481,1 16.2585095,1 L4.64092309,1 Z"></path>
>>>>>>> da6bfd9a1 (create stories for and reorganize all icons.)
>>>>>>> 870ec5de027253473c4873180244e197b1cf661c
      </g>
    </g>
  </svg>;
};
CategoryIcon.propTypes = {

  /**
   * Sets the color of the component. Default color is white.
   */
  color: PropTypes.string,

  /**
   * Sets height of the component, width is set automatically by the svg viewbox property. Default height is '20px'.
   */
  size: PropTypes.number,

  /**
   * Sets the className of the component. Default className is ''.
   */
  cname: PropTypes.string
};
CategoryIcon.defaultProps = {
  color: COLORS.WHITE,
  size: 20,
  cname: ''
};
