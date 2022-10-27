import React from 'react';
import PropTypes from 'prop-types';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { ICON_SIZES } from '../../constants/AppConstants';

export const ArrowUpIcon = (props) => {
  const { size, color, className } = props;

  return <svg height={size} viewBox="0 0 16 17" version="1.1" xmlns="http://www.w3.org/2000/svg" className={className}>
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g id="arrow-up-323A45" fillRule="nonzero" fill={color}>
        <path d="M14.6906247,7.60937528 C14.4994846,7.38477753 14.2512494,7.27252584 13.9456413,7.27252584
        L7.73926841,7.27252584 L10.3223468,4.64071461 C10.5457245,4.41328539 10.6573207,4.14077303 10.6573207,3.82333483
        C10.6573207,3.50605393 10.5457553,3.23354157 10.3223468,3.00601798 L9.66113777,2.34128539 C9.43785273,2.11385618
        9.17334442,2 8.86773634,2 C8.55619952,2 8.28869596,2.11373034 8.06547268,2.34128539 L2.32620428,8.1797573
        C2.10872447,8.41328989 2,8.68577079 2,8.99713708 C2,9.31454382 2.10872447,9.58400449 2.32620428,9.80545618
        L8.06547268,15.6619236 C8.29465558,15.8835011 8.56209739,15.9943685 8.86773634,15.9943685 C9.17914964,15.9943685
        9.44362708,15.8835011 9.66110689,15.6619236 L10.3223159,14.9794472 C10.5456936,14.7639101 10.6572898,14.4943236
        10.6572898,14.1711281 C10.6572898,13.8475865 10.5457245,13.578 10.3223159,13.3625888 L7.73923753,10.7218112
        L13.9456105,10.7218112 C14.2511876,10.7218112 14.4994537,10.6095281 14.6905938,10.3849618 C14.8815487,10.160364
        14.9769644,9.88948764 14.9769644,9.5720809 L14.9769644,8.42235056 C14.9770879,8.10494382 14.8815487,7.83397303
        14.6906247,7.60937528 Z" id="Shape" transform="translate(8.488482, 8.997184) rotate(-270.000000)
        translate(-8.488482, -8.997184) "></path>
      </g>
    </g>
  </svg>;
};
ArrowUpIcon.propTypes = {

  /**
  Sets height of the component, width is set automatically by the svg viewbox property.
  Default height is 'ICON_SIZES.SMALL'.
  */
  size: PropTypes.number,

  /**
  Sets color of the component. Default value is 'COLORS.GREY_DARK'.
  */
  color: PropTypes.string,

  /**
  Adds class to the component. Default value is ''.
  */
  className: PropTypes.string
};
ArrowUpIcon.defaultProps = {
  size: ICON_SIZES.SMALL,
  color: COLORS.GREY_DARK,
  className: ''
};
