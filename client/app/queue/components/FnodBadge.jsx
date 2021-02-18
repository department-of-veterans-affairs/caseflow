import PropTypes from 'prop-types';
import * as React from 'react';

import { COLORS } from '../../constants/AppConstants';
import Badge from './Badge';
import { DateString } from '../../util/DateUtil';

/**
 * Component to display a FNOD badge if Veteran.date_of_death is not null and
 * the Veteran is the appellant.
 */

const listStyling = css({
  listStyle: 'none',
  textAlign: 'left',
  marginBottom: 0,
  padding: 0,
  '& > li': {
    marginBottom: 0,
    '& > strong': {
      color: COLORS.WHITE
    }
  }
});

const FnodBadge = (props) => {
  const { veteranAppellantDeceased, uniqueId, show, tooltipText } = props;

  if (!veteranAppellantDeceased || !show) {
    return null;
  }

  return <Badge name="fnod" displayName="FNOD" color={COLORS.RED} tooltipText={tooltipText} id={`fnod-${uniqueId}`} />;
};

FnodBadge.propTypes = {
  veteranAppellantDeceased: PropTypes.bool,
  uniqueId: PropTypes.string,
  show: PropTypes.bool,
  tooltipText: PropTypes.string
};

export default FnodBadge;
