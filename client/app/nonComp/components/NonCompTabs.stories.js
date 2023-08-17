import React from 'react';
import ReduxBase from 'app/components/ReduxBase';
import { nonCompReducer, mapDataToInitialState } from '../reducers';

import NonCompTabsUnconnected from './NonCompTabs';

const ReduxDecorator = (Story, options) => {
  const props = {
    serverNonComp: {
      featureToggles: {
        decisionReviewQueueSsnColumn: options.args.decisionReviewQueueSsnColumn
      },
      businessLineUrl: 'vha',
      baseTasksUrl: '/decision_reviews/vha',
      taskFilterDetails: {
        in_progress: {
          '["BoardGrantEffectuationTask", "Appeal"]': 1,
          '["DecisionReviewTask", "HigherLevelReview"]': 10,
          '["DecisionReviewTask", "SupplementalClaim"]': 3,
          '["VeteranRecordRequest", "Appeal"]': 1
        },
        completed: {},
        in_progress_issue_types: {
          Apportionment: 18,
          'Beneficiary Travel': 14,
          'Camp Lejune Family Member': 13,
          'Caregiver | Eligibility': 13,
          'Caregiver | Other': 12,
          'Caregiver | Revocation/Discharge': 15,
          'Caregiver | Tier Level': 13,
          CHAMPVA: 17,
          'Clothing Allowance': 7,
          'Continuing Eligibility/Income Verification Match (IVM)': 14,
          'Eligibility for Dental Treatment': 14,
          'Foreign Medical Program': 12,
          'Initial Eligibility and Enrollment in VHA Healthcare': 15,
          'Medical and Dental Care Reimbursement': 7,
          Other: 21,
          'Prosthetics | Other (not clothing allowance)': 12,
          'Spina Bifida Treatment (Non-Compensation)': 10
        },
        completed_issue_types: {}
      }
    }
  };

  return <ReduxBase reducer={nonCompReducer} initialState={mapDataToInitialState(props)}>
    <Story />
  </ReduxBase>;
};

const defaultArgs = {
  decisionReviewQueueSsnColumn: true,
};

export default {
  title: 'Queue/NonComp/NonCompTabs',
  component: NonCompTabsUnconnected,
  decorators: [ReduxDecorator],
  parameters: {},
  args: defaultArgs,
  argTypes: {
    decisionReviewQueueSsnColumn: { control: 'boolean' }
  },
};

const Template = (args) => {
  return (
    <NonCompTabsUnconnected
      {...args}
    />
  );

};

export const NonCompTabsUnconnectedStory = Template.bind({});

NonCompTabsUnconnectedStory.story = {
  name: 'Decision Review Queue'
};

NonCompTabsUnconnectedStory.parameters = {
  docs: {
    storyDescription:
      'NonCompTabs Storybook file with two tabs: in progress tasks and completed',
  },
};
