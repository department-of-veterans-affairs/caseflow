import PropTypes from 'prop-types';
import * as React from 'react';

import Badge from '../Badge';
import { COLORS } from 'app/constants/AppConstants';

/**
 * Component to display where the Intake originated from (VBMS or Caseflow)
 */

const IntakeBadge = (props) => {
  const { review } = props;
  let tooltipText = '';

  if (review.intakeFromVbms) {
    tooltipText = 'Case was intaken through VBMS';

    return <Badge
      name="vbms"
      displayName="VBMS"
      color={COLORS.PURPLE}
      tooltipText={tooltipText}
      id={`vbms-${review.id}`}
      ariaLabel="VBMS Intake"
    />;
  }
  tooltipText = 'Case was intaken through Caseflow';

  return <Badge
    name="caseflow"
    displayName="CF"
    color={COLORS.COLOR_COOL_BLUE_LIGHTER}
    tooltipText={tooltipText}
    id={`cf-${review.id}`}
    ariaLabel="Caseflow Intake"
  />;

};

IntakeBadge.propTypes = {
  review: PropTypes.object,
};

export default IntakeBadge;
