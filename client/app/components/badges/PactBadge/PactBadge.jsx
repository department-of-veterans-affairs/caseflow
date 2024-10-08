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
  const decisionIssues = appeal?.decisionIssues;

  // check the decisions for pact changes in flight
  if (decisionIssues && decisionIssues?.length > 0) {
    if (!decisionIssues.some((issue) => issue.pact_status === true)) {
      return null;
    }
  } else if (!appeal?.pact) {
    // if decisions are empty/undefined, use appeal model mst check
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
