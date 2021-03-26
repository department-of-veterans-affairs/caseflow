import React from 'react';
import PropTypes from 'prop-types';

import DocketTypeBadge from '../../../components/DocketTypeBadge';
import { ReadOnly } from '../details/ReadOnly';

import { formatTimeSlotLabel } from '../../utils';

export const AppealInformation = ({ appeal }) => {
  console.log('APPEAL: ', appeal);

  return (
    <div className="schedule-veteran-appeals-info">
      <h2>Appeal Information</h2>
      <ReadOnly
        spacing={0}
        label="Veteran Name"
        text={appeal?.appellantFullName}
      />
      <ReadOnly spacing={15} label="Issues" text="" />
      <ReadOnly spacing={15} label="Appeal Stream" text="" />
      <ReadOnly
        spacing={15}
        label="Docket Number"
        text={
          <span>
            <DocketTypeBadge
              name={appeal?.docketName}
              number={appeal?.docketNumber}
            />
            {appeal?.docketNumber}
          </span>
        }
      />
      <ReadOnly spacing={15} label="Power of Attorney" text="" />
      <ReadOnly spacing={15} label="Date of Death" text="" />
    </div>
  );
};

AppealInformation.propTypes = {
  appeal: PropTypes.object,
};
