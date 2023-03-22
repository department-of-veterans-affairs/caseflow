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
        completed: {}
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
