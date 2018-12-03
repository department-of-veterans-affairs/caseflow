import { css } from 'glamor';
import _ from 'lodash';
import * as React from 'react';

import Tooltip from '../../components/Tooltip';
import { COLORS } from '../../constants/AppConstants';

import { DateString } from '../../util/DateUtil';

const badgeStyling = css({
  display: 'inline-block',
  color: COLORS.WHITE,
  background: COLORS.PURPLE,
  borderRadius: '.5rem',
  lineHeight: '2rem',
  marginLeft: '1rem',
  padding: '0 .5rem'
});

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

const DocketTypeBadge = ({ appeal }) => {
  console.log('****************')
  if (!appeal) {
    return null;
  }

  const tooltipText = <div>
    This case has specialty cases.
  </div>;

  console.log('******* SCT *********')
  console.log(tooltipText)

  // We expect this badge to be shown in a table, so we use this to get rid of the standard table padding.
  return <span {...css({ marginRight: '-3rem' })} className="cf-hearing-badge">
    <Tooltip id={`badge-${appeal.externalId}`} text={tooltipText} position="bottom">
      <span {...badgeStyling}>SCT</span>
    </Tooltip>
  </span>;
};

export default DocketTypeBadge;
