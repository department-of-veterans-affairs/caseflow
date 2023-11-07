import React from 'react';
import LeverHistory from './LeverHistory';
import { formattedHistory } from 'test/data/adminCaseDistributionLevers';

export default {
  title: 'Admin/Caseflow Distribution/Lever History',
  component: LeverHistory,
};

export const Primary = () => <LeverHistory historyData={formattedHistory} />;

Primary.story = {
  name: 'Lever Audit Table'
};

