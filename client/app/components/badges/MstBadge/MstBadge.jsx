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
  const decisionIssues = appeal?.decisionIssues;

  // check the decisions for mst changes in flight
  if (decisionIssues?.length > 0) {
    if (!decisionIssues.some((issue) => issue.mst_status === true)) {
      return null;
    }
  } else if (!appeal?.mst) {
    // if decisions are empty/undefined, use appeal model mst check
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
