import PropTypes from 'prop-types';
import * as React from 'react';

import Badge from '../Badge';
import { CC_BADGE_TOOLTIP, CC_BADGE_TOOLTIP_LONG } from 'app/../COPY';
import { COLORS } from 'app/constants/AppConstants';

/**
 * Component to display if the appeal is a contested claim.
 */

const ContestedClaimBadge = (props) => {
  const { appeal, longTooltip } = props;

  if (!appeal.contested_claim) {
    return null;
  }

  const tooltipText = <div style={{ whiteSpace: 'pre-line' }}>
    { longTooltip ? CC_BADGE_TOOLTIP_LONG : CC_BADGE_TOOLTIP }
  </div>;

  return <Badge name="contested" id="contested-badge"
    displayName="CC" color={COLORS.PURPLE} tooltipText={tooltipText} />;
};

ContestedClaimBadge.propTypes = {
  appeal: PropTypes.object,
  longTooltip: PropTypes.bool
};

export default ContestedClaimBadge;
