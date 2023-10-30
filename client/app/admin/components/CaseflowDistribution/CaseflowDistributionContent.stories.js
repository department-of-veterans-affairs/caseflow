import React from 'react';
import CaseflowDistributionContent from './CaseflowDistributionContent';
import { formattedHistory } from '../../../../../client/test/data/adminCaseDistributionLevers';

export default {
  title: 'CaseDistribution/Caseflow Distribution Content',
  component: CaseflowDistributionContent,
};

export const Primary = () =>
  <CaseflowDistributionContent
    levers = {[]}
    activeLevers = {[]}
    inactiveLevers = {[]}
    saveChanges = {[]}
    formattedHistory={formattedHistory}
    isAdmin
  />;

Primary.story = {
  name: 'Case Distribution for Admin'
};

