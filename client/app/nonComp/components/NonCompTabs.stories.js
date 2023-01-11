import React from 'react';
import ReduxBase from 'app/components/ReduxBase';
import { nonCompReducer, mapDataToInitialState } from '../reducers';

import NonCompTabsUnconnected from './NonCompTabs';

const ReduxDecorator = (Story) => {
  const props = {
    serverNonComp: {
      businessLineUrl: 'vha',
      baseTasksUrl: '/decision_reviews/vha',
    }
  };

  return <ReduxBase reducer={nonCompReducer} initialState={mapDataToInitialState(props)}>
    <Story />
  </ReduxBase>;
};

const defaultArgs = {

};

export default {
  title: 'Queue/NonComp/NonCompTabs',
  component: NonCompTabsUnconnected,
  decorators: [ReduxDecorator],
  parameters: {},
  args: defaultArgs,
  argTypes: {
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
