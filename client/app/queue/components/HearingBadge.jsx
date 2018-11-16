import { css } from 'glamor';
import _ from 'lodash';
import * as React from 'react';

import Tooltip from '../../components/Tooltip';
import { COLORS } from '../../constants/AppConstants';

import { DateString } from '../../util/DateUtil';

const badgeStyling = css({
  display: 'inline-block',
  color: COLORS.WHITE,
  background: COLORS.GREEN,
  borderRadius: '.5rem',
  lineHeight: '2rem',
  marginLeft: '1rem',
  padding: '0 1rem'
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

const DocketTypeBadge = ({ hearing }) => {
  if (!hearing) {
    return null;
  }

  const tooltipText = <div>
    This case has a hearing associated with it.
    <ul {...listStyling}>
      <li>Judge: <strong>{hearing.heldBy}</strong></li>
      <li>Disposition: <strong>{_.startCase(hearing.disposition)}</strong></li>
      <li>Date: <strong><DateString date={hearing.date} /></strong></li>
      <li>Type: <strong>{_.startCase(hearing.type)}</strong></li>
    </ul>
  </div>;

  return <div {...css({ marginRight: '-3rem' })}>
    <Tooltip id={`badge-${hearing.id}`} text={tooltipText} position="bottom">
      <span {...badgeStyling}>H</span>
    </Tooltip>
  </div>;
};

export default DocketTypeBadge;
