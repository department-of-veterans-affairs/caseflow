import React from 'react';

import faker from 'faker';

import { SubstitutionProcessedTimelineEvent } from './SubstitutionProcessedTimelineEvent';

const timelineEvent = {
  createdAt: new Date(),
  createdBy: faker.name.findName(),
  substituteFullName: faker.name.findName(),
  originalAppellantFullName: faker.name.findName(),
};

export default {
  title: 'Queue/Substitute Appellant/SubstitutionProcessedTimelineEvent',
  component: SubstitutionProcessedTimelineEvent,
  decorators: [(StoryFn) => <table><StoryFn /></table>],
  parameters: {},
  args: {
    timelineEvent,
  },
  argTypes: {},
};

const Template = (args) => <SubstitutionProcessedTimelineEvent {...args} />;

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'Displays on Case Timeline to denote date appellant substitution was processed',
  },
};
