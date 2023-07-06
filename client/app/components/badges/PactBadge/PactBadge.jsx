import PropTypes from 'prop-types';
import * as React from 'react';

import Badge from '../Badge';
import { COLORS } from 'app/constants/AppConstants';
import { connect } from 'react-redux';

/**
 * Component to display if the appeal is a pact.
 */

const PactBadge = (props) => {
  const { appeal, appealDetails } = props;

  if (appealDetails[appeal.externalId]?.issues) {
    const issues = appealDetails[appeal.externalId].issues;

    if (!issues.some((issue) => issue.pact_status === true)) {
      return null;
    }
  } else if (!appeal?.pact) {
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
  appeal: PropTypes.object,
  appealDetails: PropTypes.object
};

const mapStateToProps = (state) => ({
  appealDetails: state.queue.appealDetails,
});

export default connect(
  mapStateToProps
)(PactBadge);

