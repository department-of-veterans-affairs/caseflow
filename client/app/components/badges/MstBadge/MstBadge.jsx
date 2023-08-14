import PropTypes from 'prop-types';
import * as React from 'react';

import Badge from '../Badge';
import { COLORS } from 'app/constants/AppConstants';

/**
 * Component to display if the appeal is a mst.
 */

const MstBadge = (props) => {
  const { appeal } = props;

  // During decision review workflow, saved/staged changes made are updated to appeal.decisionIssues
  // if legacy check issues for changes, if ama check decision for changes
  const issues = (appeal.isLegacyAppeal || appeal.type === 'LegacyAppeal') ? appeal.issues : appeal.decisionIssues;

  // check the issues/decisions for mst/pact changes in flight
  if (issues && issues?.length > 0) {
    if (!issues.some((issue) => issue.mst_status === true)) {
      return null;
    }
  } else if (!appeal?.mst) {
    // if issues are empty/undefined, use appeal model mst check
    return null;
  }

  const tooltipText = 'Appeal has issue(s) related to Military Sexual Trauma';

  return <Badge
    name="mst"
    displayName="MST"
    color={COLORS.GRAY}
    tooltipText={tooltipText}
    id={`mst-${appeal.id}`}
    ariaLabel="mst"
  />;
};

MstBadge.propTypes = {
  appeal: PropTypes.object,
};

export default MstBadge;
