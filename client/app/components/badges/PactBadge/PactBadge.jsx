import PropTypes from 'prop-types';
import * as React from 'react';

import Badge from '../Badge';
import { COLORS } from 'app/constants/AppConstants';

/**
 * Component to display if the appeal is a pact.
 */

const PactBadge = (props) => {
  const { appeal } = props;

  // During decision review workflow, saved/staged changes made are updated to appeal.decisionIssues
  // if legacy check issues for changes, if ama check decision for changes
  const issues = (appeal.isLegacyAppeal || appeal.type === 'LegacyAppeal') ? appeal.issues : appeal.decisionIssues;

  // check the issues/decisions for mst/pact changes in flight
  if (issues && issues?.length > 0) {
    if (!issues.some((issue) => issue.pact_status === true)) {
      return null;
    }
  } else if (!appeal?.pact) {
    // if issues are empty/undefined, use appeal model mst check
    return null;
  }

  const tooltipText = 'Appeal has issue(s) related to Promise to Address Comprehensive Toxics (PACT) Act.';

  return <Badge
    name="pact"
    displayName="PACT"
    color={COLORS.ORANGE}
    tooltipText={tooltipText}
    id={`pact-${appeal.id}`}
    ariaLabel="pact"
  />;
};

PactBadge.propTypes = {
  appeal: PropTypes.object
};

export default PactBadge;
