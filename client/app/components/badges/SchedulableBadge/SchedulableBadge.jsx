import PropTypes from 'prop-types';
import * as React from 'react';

import Badge from '../Badge';
import { COLORS } from 'app/constants/AppConstants';

/**
 * Component to display if a National Hearing Queue entry is considered 'schedulable'/able to be scheduled.
 */

const SchedulableBadge = ({ taskId }) => {
  const tooltipText = 'Indicates whether an appeal is eligible to have a hearing scheduled on its behalf.';

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
