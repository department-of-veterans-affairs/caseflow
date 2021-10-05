import PropTypes from 'prop-types';
import * as React from 'react';

import Badge from './Badge';
import { CC_TOOLTIP_HEADER } from '../../../COPY.json';
import { COLORS } from 'app/constants/AppConstants';

/**
 * Component to display if the appeal is a contested claim.
 */

const CCBadge = (props) => {
  const { appeal } = props;

  if (!appeal.contested_claim) {
    return null;
  }

  const tooltipText = <div>
    { CC_TOOLTIP_HEADER }
  </div>;

  return <Badge name="contested" displayName="CC" color={COLORS.PURPLE} tooltipText={tooltipText} />;
};

CCBadge.propTypes = {
  appeal: PropTypes.object
};

export default CCBadge;
