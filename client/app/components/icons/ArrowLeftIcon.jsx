import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

export const ArrowLeftIcon = (props) => {
  const { size, color, className } = props;

  return <svg height={size} viewBox="0 0 16 17" version="1.1" xmlns="http://www.w3.org/2000/svg" className={className}>
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g id="arrow-left-323A45" fillRule="nonzero" fill={color}>
        <path d="M13.6906247,7.60937528 C13.4994846,7.38477753 13.2512494,7.27252584 12.9456413,7.27252584
        L6.73926841,7.27252584 L9.32234679,4.64071461 C9.54572447,4.41328539 9.65732067,4.14077303 9.65732067,3.82333483
        C9.65732067,3.50605393 9.54575534,3.23354157 9.32234679,3.00601798 L8.66113777,2.34128539 C8.43785273,2.11385618
        8.17334442,2 7.86773634,2 C7.55619952,2 7.28869596,2.11373034 7.06547268,2.34128539 L1.32620428,8.1797573
        C1.10872447,8.41328989 1,8.68577079 1,8.99713708 C1,9.31454382 1.10872447,9.58400449 1.32620428,9.80545618
        L7.06547268,15.6619236 C7.29465558,15.8835011 7.56209739,15.9943685 7.86773634,15.9943685 C8.17914964,15.9943685
        8.44362708,15.8835011 8.66110689,15.6619236 L9.32231591,14.9794472 C9.54569359,14.7639101 9.65728979,14.4943236
        9.65728979,14.1711281 C9.65728979,13.8475865 9.54572447,13.578 9.32231591,13.3625888 L6.73923753,10.7218112
        L12.9456105,10.7218112 C13.2511876,10.7218112 13.4994537,10.6095281 13.6905938,10.3849618 C13.8815487,10.160364
        13.9769644,9.88948764 13.9769644,9.5720809 L13.9769644,8.42235056 C13.9770879,8.10494382 13.8815487,7.83397303
        13.6906247,7.60937528 Z" id="Shape" transform="translate(7.488482, 8.997184) scale(-1, 1) rotate(-180.000000)
        translate(-7.488482, -8.997184) "></path>
      </g>
    </g>
  </svg>;

};
ArrowLeftIcon.propTypes = {

  /**
  Sets height of the component, width is set automatically by the svg viewbox property. Default height is '17px'.
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
ArrowLeftIcon.defaultProps = {
  size: ICON_SIZES.SMALL,
  color: COLORS.GREY_DARK,
  className: ''
};
