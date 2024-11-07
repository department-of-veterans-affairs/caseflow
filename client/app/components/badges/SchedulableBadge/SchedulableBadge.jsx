import PropTypes from 'prop-types';
import * as React from 'react';

import Badge from '../Badge';
import { COLORS } from 'app/constants/AppConstants';

/**
 * Component to display if a National Hearing Queue entry is considered 'schedulable'/able to be scheduled.
 */

const SchedulableBadge = ({ taskId }) => {
  const tooltipText = 'This case is marked as "ready to be scheduled" for a hearing.';

  return <Badge
    name="schedulable"
    displayName="SCH"
    color={COLORS.GOLD_LIGHT}
    tooltipText={tooltipText}
    id={`schedulable-${taskId}`}
    ariaLabel="schedulable"
  />;
};

SchedulableBadge.propTypes = {
  taskId: PropTypes.string
};

export default SchedulableBadge;
