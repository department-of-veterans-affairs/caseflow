import React from 'react';

import { SubstituteAppellantTimelineEvent } from './SubstituteAppellantTimelineEvent';

const timelineEvent = {
  substitutionDate: new Date()
};

export default {
  title: 'Queue/Substitute Appellant/SubstituteAppellantTimelineEvent',
  component: SubstituteAppellantTimelineEvent,
  decorators: [(StoryFn) => <table><StoryFn /></table>],
  parameters: {},
  args: {
    timelineEvent,
  },
  argTypes: {},
};

const Template = (args) => <SubstituteAppellantTimelineEvent {...args} />;

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'Displays on Case Timeline to denote date of appellant substitution',
  },
};
