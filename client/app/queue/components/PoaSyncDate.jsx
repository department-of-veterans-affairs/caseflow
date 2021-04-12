import React from 'react';
import PropTypes from 'prop-types';
// import { editAppeal, poaSyncDateUpdates } from '../QueueActions';
// import { useDispatch, useSelector } from 'react-redux';
// import ApiUtil from '../../util/ApiUtil';
import { formatDateStr } from '../../util/DateUtil';
import COPY from '../../../COPY';
import { css } from 'glamor';
import { sprintf } from 'sprintf-js';

import { boldText } from '../constants';

export const textStyling = css({
  display: 'flex',
  justifyContent: 'space-between',
  fontSize: '.8em'
});

export const PoaRefresh = ({ powerOfAttorney }) => {
  const poaSyncInfo = {
    poaSyncDate: formatDateStr(powerOfAttorney.poa_last_synced_at)
  };

  const lastSyncedCopy = sprintf(COPY.CASE_DETAILS_POA_LAST_SYNC_DATE_COPY, poaSyncInfo);

  return (
    <div {...textStyling}>
      <i>Power of Attorney (POA) data comes from VBMS. To refresh POA, please click the "Refresh POA" button.</i>
      <i {...boldText}>{lastSyncedCopy}</i>
    </div>
  );
};

PoaRefresh.propTypes = {
  powerOfAttorney: PropTypes.shape({
    poa_last_synced_at: PropTypes.string
  })

};
