import PropTypes from 'prop-types';
import * as React from 'react';

import { COLORS } from '../../constants/AppConstants';
import Badge from './Badge';

/**
 * Component to display a FNOD badge if Veteran.date_of_death is not null and
 * the Veteran is the appellant.
 */

const FnodBadge = (props) => {
  const { appeal, featureToggles } = props;

  if (!appeal.veteranAppellantDeceased || !featureToggles.fnod_badge) {
    return null;
  }

  const tooltipText = 'Date of Death Reported';

  return <Badge name="fnod" displayName="FNOD" color={COLORS.RED} tooltipText={tooltipText} id={`fnod-${appeal.id}`} />;
};

FnodBadge.propTypes = {
  appeal: PropTypes.object,
  featureToggles: PropTypes.object
};

export default FnodBadge;
