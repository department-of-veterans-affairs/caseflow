import { css } from 'glamor';
import * as React from 'react';

import Tooltip from '../../components/Tooltip';
import { COLORS } from '../../constants/AppConstants';

const badgeStyling = css({
  display: 'inline-block',
  color: COLORS.WHITE,
  background: COLORS.RED,
  borderRadius: '.5rem',
  lineHeight: '2rem',
  marginLeft: '1rem',
  padding: '0 .5rem'
});

const DocketTypeBadge = ({ appeal }) => {
  if (!appeal) {
    return null;
  }

  const tooltipText = <div>
    This case is Advanced on the Docket.
  </div>;

  // We expect this badge to be shown in a table, so we use this to get rid of the standard table padding.
  return <span {...css({ marginRight: '-3rem' })} className="cf-hearing-badge">
    <Tooltip id={`badge-${appeal.id}`} text={tooltipText} position="bottom">
      <span {...badgeStyling}>AOD</span>
    </Tooltip>
  </span>;
};

export default DocketTypeBadge;
