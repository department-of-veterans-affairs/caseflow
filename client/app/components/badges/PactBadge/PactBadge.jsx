import PropTypes from 'prop-types';
import * as React from 'react';

import Badge from '../Badge';
import { COLORS } from 'app/constants/AppConstants';

/**
 * Component to display if the appeal is a pact.
 */

const PactBadge = (props) => {
  const { appeal } = props;

  if (!appeal.pact) {
    return null;
  }

  const tooltipText = "";

  return <Badge
    name="pact"
    displayName="PACT"
    color={COLORS.GRAY}
    tooltipText={tooltipText}
    id={`pact-${appeal.id}`}
    ariaLabel="pact"
  />;
};

PactBadge.propTypes = {
  appeal: PropTypes.object
};

export default PactBadge;
