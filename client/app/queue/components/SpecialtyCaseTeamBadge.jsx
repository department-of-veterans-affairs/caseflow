import { css } from 'glamor';
import * as React from 'react';

import { COLORS } from '../../constants/AppConstants';

const badgeStyling = css({
  display: 'inline-block',
  color: COLORS.WHITE,
  background: COLORS.PURPLE,
  borderRadius: '.5rem',
  lineHeight: '2rem',
  marginLeft: '1rem',
  padding: '0 1rem'
});

const SpecialtyCaseTeamBadge = () => {
  // We expect this badge to be shown in a table, so we use this to get rid of the standard table padding.
  return <div {...css({ marginRight: '-2rem' })}>
    <span {...badgeStyling}>SCT</span>
  </div>;
};

export default SpecialtyCaseTeamBadge;
