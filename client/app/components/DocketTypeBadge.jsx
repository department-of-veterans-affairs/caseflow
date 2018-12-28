import { css } from 'glamor';
import _ from 'lodash';
import * as React from 'react';

import Tooltip from './Tooltip';
import { COLORS } from '../constants/AppConstants';

const badgeStyling = css({
  display: 'inline-block',
  background: COLORS.GREY_LIGHT,
  borderRadius: '1rem',
  lineHeight: '2rem',
  marginRight: '0.5rem',
  padding: '0 1rem'
});

const DocketTypeBadge = ({ name, number }) => {
  if (!name) {
    return null;
  }

  // "Hearing Request" docket type is stored in the database as "hearing".
  // Change it here so later transformations affect it properly.
  const docketName = name === 'hearing' ? 'hearing_request' : name;

  return <Tooltip id={`badge-${number}`} text={_.startCase(_.toLower(docketName))} position="bottom">
    <span {...badgeStyling}>{_.toUpper(docketName.charAt(0))}</span>
  </Tooltip>;
};

export default DocketTypeBadge;
