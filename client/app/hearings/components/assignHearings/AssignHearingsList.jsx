import React from 'react';
import PropTypes from 'prop-types';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import DocketTypeBadge from '../../../components/DocketTypeBadge';
import { ReadOnly } from '../details/ReadOnly';
import { renderAppealType } from '../../../queue/utils';
import { formatDateStr } from '../../../util/DateUtil';

export const AssignHearingsList = ({ appeal }) => {
  return (
    <div />
  );
};

AssignHearingsList.propTypes = {
  appeal: PropTypes.object,
};
