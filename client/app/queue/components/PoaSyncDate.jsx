import React from 'react';
// import { editAppeal, poaSyncDateUpdates } from '../QueueActions';
// import { useDispatch, useSelector } from 'react-redux';
// import ApiUtil from '../../util/ApiUtil';
import COPY from '../../../COPY';
import { css } from 'glamor';
import { sprintf } from 'sprintf-js';

import { boldText } from '../constants';

export const textStyling = css({
  display: 'flex',
  justifyContent: 'space-between',
  fontSize: '.8em'
});

export const PoaSyncDate = () => {

  const poaSyncInfo = {
    poaSyncDate: '04/05/2021'
  };

  const lastSyncedCopy = sprintf(COPY.CASE_DETAILS_POA_LAST_SYNC_DATE_COPY, poaSyncInfo);
  // const dispatch = useDispatch();
  // const handleClick = ({ poaDate }) => {

  //   const payload = {
  //     data: {
  //       last_synced_at: poaDate
  //     },
  //   };

  //   ApiUtil.patch(`/appeals/${appealId}/poa_date_update`, payload).then((data) => {
  //     dispatch(editAppeal(appealId, {
  //       poaDate: data.body.poaDate
  //     }));
  //     dispatch(poaSyncDateUpdates(appealId, data.body.poaSyncDate));
  //   });
  // };

  return (
    <div {...textStyling}>
      <i>Power of Attorney (POA) data comes from VBMS. To refresh POA, please click the "Refresh POA" button.</i>
      <i {...boldText}>{lastSyncedCopy}</i>
    </div>
  );
};
