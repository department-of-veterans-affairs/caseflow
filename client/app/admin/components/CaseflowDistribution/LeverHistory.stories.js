import React from 'react';
import LeverHistory from './LeverHistory';
import { formattedHistory } from '../../../../../client/test/data/adminCaseDistributionLevers';

export default {
  title: 'CaseDistribution/Lever History',
  component: LeverHistory,
};

export const Primary = () => <LeverHistory historyData={formattedHistory} />;

Primary.story = {
  name: 'Lever Audit Table'
};

