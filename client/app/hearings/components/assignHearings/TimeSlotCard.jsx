import React from 'react';
import PropTypes from 'prop-types';

import DocketTypeBadge from '../../../components/DocketTypeBadge';
import { ReadOnly } from '../details/ReadOnly';
import { renderAppealType } from '../../../queue/utils';
import { formatDateStr } from '../../../util/DateUtil';

export const TimeSlotCard = ({ appeal }) => {
  return (
    <div />
  );
};

TimeSlotCard.propTypes = {
  appeal: PropTypes.object,
};
