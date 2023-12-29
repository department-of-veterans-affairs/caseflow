import React, { useState, useEffect } from 'react';
import { bindActionCreators } from 'redux';
import { connect, useSelector } from 'react-redux';

import COPY from '../../../../COPY';

import ActiveDataElements from './ActiveDataElements';
import InactiveDataElements from './InactiveDataElements';
import ChangeHistory from './ChangeHistory';

export const CaseflowDistributionAdmin = (props) => {
  const testRedux = useSelector((state) => state.caseflowDistribution);

  return (
    <div>
      <h1>Administration</h1>

      <div>
        <h2>{COPY.CASE_DISTRIBUTION_TITLE}</h2>

        <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_ALGORITHM_DESCRIPTION}</p>

        <ActiveDataElements />
        <InactiveDataElements />
        <ChangeHistory />
      </div>
    </div>
  );
};

export default connect()(CaseflowDistributionAdmin);
