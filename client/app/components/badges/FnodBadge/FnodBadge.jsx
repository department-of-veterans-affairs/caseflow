import PropTypes from 'prop-types';
import * as React from 'react';

import { COLORS } from 'app/constants/AppConstants';
import Badge from '../Badge';

/**
 * Component to display a FNOD badge if Veteran.date_of_death is not null and
 * the Veteran is the appellant.
 */

const FnodBadge = (props) => {
  const { veteranAppellantDeceased, uniqueId, tooltipText } = props;

  if (!veteranAppellantDeceased) {
    return null;
  }

  return <Badge name="fnod" displayName="FNOD" color={COLORS.RED} tooltipText={tooltipText} id={`fnod-${uniqueId}`}
    ariaLabel="fnod status" />;
};

FnodBadge.propTypes = {
  veteranAppellantDeceased: PropTypes.bool,
  uniqueId: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.number,
  ]),
  tooltipText: PropTypes.object
};

export default FnodBadge;
