import PropTypes from 'prop-types';
import * as React from 'react';

import Badge from '../Badge';
import { COLORS } from 'app/constants/AppConstants';

/**
 * Component to display if the appeal is a mst.
 */

const MstBadge = (props) => {
  const { appeal } = props;

  if (!appeal?.mst) {
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
  appeal: PropTypes.object
};

export default MstBadge;
