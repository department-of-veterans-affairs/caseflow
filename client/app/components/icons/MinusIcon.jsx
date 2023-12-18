import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

export const MinusIcon = (props) => {

  const { color, size, className } = props;

  return (
    <svg height={size} viewBox="0 0 15 15" className={className}>
      <g fillRule="nonzero" fill={color}>
        <Link><rect width="25" height="5" x="0" y="5" /></Link>
      </g>
    </svg>
  );

};
MinusIcon.propTypes = {
  color: PropTypes.string,
  size: PropTypes.number,
  className: PropTypes.string,
};

MinusIcon.defaultProps = {
  color: COLORS.WHITE,
  size: ICON_SIZES.XSMALL,
  className: ''
};
