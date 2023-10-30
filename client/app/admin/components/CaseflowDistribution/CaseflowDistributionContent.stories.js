import React from 'react';
import CaseflowDistributionContent from './CaseflowDistributionContent';
import { formattedHistory } from '../../../../../client/test/data/adminCaseDistributionLevers';
import { formatted_history, formatted_levers } from '../../../../../client/test/data/formattedCaseDistributionData';

export default {
  title: 'CaseDistribution/Caseflow Distribution Content',
  component: CaseflowDistributionContent,
};

export const Primary = () =>
  <CaseflowDistributionContent
    levers = {formatted_levers}
    activeLevers = {[]}
    inactiveLevers = {[]}
    saveChanges = {[]}
    formattedHistory={formatted_history}
    isAdmin
  />;

Primary.story = {
  name: 'Case Distribution for Admin'
};

