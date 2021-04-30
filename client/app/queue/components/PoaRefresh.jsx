import React from 'react';
import PropTypes from 'prop-types';
import { formatDateStr } from '../../util/DateUtil';
import COPY from '../../../COPY';
import { css } from 'glamor';
import { sprintf } from 'sprintf-js';
import { useSelector } from 'react-redux';

import { boldText } from '../constants';

import { PoaRefreshButton } from './PoaRefreshButton';

export const textStyling = css({
  display: 'flex',
  justifyContent: 'space-between'
});

export const syncStyling = css({
  textAlign: 'right',
  width: '100%'
});

export const divStyling = css({
  width: '33%'
});

export const PoaRefresh = ({ powerOfAttorney, appealId }) => {
  const poaSyncInfo = {
    poaSyncDate: formatDateStr(powerOfAttorney.poa_last_synced_at)
  };

  const lastSyncedCopy = sprintf(COPY.CASE_DETAILS_POA_LAST_SYNC_DATE_COPY, poaSyncInfo);
  const viewPoaRefresh = useSelector((state) => state.ui.featureToggles.poa_sync_date);


  return <React.Fragment>
    {viewPoaRefresh &&
    <div {...textStyling}>
      <i>Power of Attorney (POA) data comes from VBMS. To refresh POA, please click the "Refresh POA" button.</i>
      <div {...divStyling}></div>
      <div {...boldText}{...syncStyling}><i>{lastSyncedCopy}</i>
        <PoaRefreshButton appealId={appealId} poaId={powerOfAttorney.representative_id} />
      </div>
    </div>
    }
  </React.Fragment>;
};

PoaRefresh.propTypes = {
  powerOfAttorney: PropTypes.shape({
    poa_last_synced_at: PropTypes.string
  })

};
