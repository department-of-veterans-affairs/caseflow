import PropTypes from 'prop-types';
import * as React from 'react';

import { COLORS } from '../../constants/AppConstants';
import Badge from './Badge';

/**
 * Component to display a FNOD badge if Veteran.date_of_death is not null and
 * the Veteran is the appellant.
 */

const FnodBadge = (props) => {
  const { veteranAppellantDeceased, uniqueId, tooltipText } = props;

  if (!veteranAppellantDeceased) {
    return null;
  }

  return <Badge name="fnod" displayName="FNOD" color={COLORS.RED} tooltipText={tooltipText} id={`fnod-${uniqueId}`} />;
};

FnodBadge.propTypes = {
  veteranAppellantDeceased: PropTypes.bool,
  uniqueId: PropTypes.string,
  tooltipText: PropTypes.string
};

export default FnodBadge;
