import PropTypes from 'prop-types';
import * as React from 'react';

import { COLORS } from '../../constants/AppConstants';
import Badge from './Badge';

/**
 * Component to display a FNOD badge if Veteran.date_of_death is not null and
 * the Veteran is the appellant.
 */

const FnodBadge = (props) => {
  const { appeal, show, tooltipText } = props;

  if (!appeal.veteranAppellantDeceased || !show) {
    return null;
  }

  return <Badge name="fnod" displayName="FNOD" color={COLORS.RED} tooltipText={tooltipText} id={`fnod-${appeal.id}`} />;
};

FnodBadge.propTypes = {
  appeal: PropTypes.object,
  show: PropTypes.bool,
  tooltipText: PropTypes.string
};

export default FnodBadge;
