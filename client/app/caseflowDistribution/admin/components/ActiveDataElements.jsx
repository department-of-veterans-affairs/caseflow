import React, { useState, useEffect } from 'react';
import { useSelector } from 'react-redux';

import COPY from '../../../../COPY';

import AffinityDays from './ActiveDataElements/AffinityDays';
import BatchSize from './ActiveDataElements/BatchSize';
import ExclusionTable from './ActiveDataElements/ExclusionTable';
import NonPriorityDistributionGoals from './ActiveDataElements/NonPriorityDistributionGoals';

export const ActiveDataElements = (props) => {
  return (
    <div id="active-data-elements">
      <h2>
        <span>{COPY.CASE_DISTRIBUTION_ACTIVE_LEVERS_TITLE}</span>
      </h2>
      <div>
        <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_ACTIVE_LEVERS_DESCRIPTION}</p>

        <div className="cf-help-divider"></div>

        <ExclusionTable />
        <BatchSize />
        <AffinityDays />
        <NonPriorityDistributionGoals />
      </div>
    </div>
  );
};

export default ActiveDataElements;
