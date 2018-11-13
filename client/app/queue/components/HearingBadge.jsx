import { css } from 'glamor';
import _ from 'lodash';
import * as React from 'react';

import Tooltip from '../../components/Tooltip';
import { COLORS } from '../../constants/AppConstants';
import { DISPOSITION_OPTIONS, HEARING_OPTIONS } from '../../hearings/constants/constants';

import { DateString } from '../../util/DateUtil';
// /Users/joe/code/thirdslant/caseflow/client/app/queue/components/HearingBadge.jsx
// /Users/joe/code/thirdslant/caseflow/client/app/util/DateUtil.js
// /Users/joe/code/thirdslant/caseflow/client/app/hearings/constants/constants.js

const badgeStyling = css({
  display: 'inline-block',
  color: COLORS.WHITE,
  background: COLORS.GREEN,
  borderRadius: '.5rem',
  lineHeight: '2rem',
  marginRight: '0.5rem',
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

const DocketTypeBadge = ({ hearing, name, number }) => {
  if (!name) {
    return null;
  }

  const dispositionText = _.find(DISPOSITION_OPTIONS, ['value', hearing.disposition]).label;

  // "Hearing Request" docket type is stored in the database as "hearing".
  // Change it here so later transformations affect it properly.
  const tooltipText = <div>
    This case has a hearing associated with it.
    <ul {...listStyling}>
      <li>Judge: <strong>{hearing.heldBy}</strong></li>
      <li>Disposition: <strong>{dispositionText}</strong></li>
      <li>Date: <strong><DateString date={hearing.date} /></strong></li>
      <li>Type: <strong>{HEARING_OPTIONS[hearing.type]}</strong></li>
    </ul>
  </div>;

  return <Tooltip id={`badge-${number}`} text={tooltipText} position="bottom">
    <span {...badgeStyling}>H</span>
  </Tooltip>;
};

export default DocketTypeBadge;
