import React from 'react';

import { CaseTimeline } from './CaseTimeline';

import { splitAppeal } from '../../test/data/appeals';
import { splitAppealTask, amaTasksSplit } from '../../test/data/tasks';
import { queueWrapper as Wrapper } from '../../test/data/stores/queueStore';

export default {
  title: 'Queue/CaseTimeline/SplitAppeal',
  component: CaseTimeline,
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 760,
    },
  },
};

const Template = (args) => (
  <Wrapper {...args} >
    <CaseTimeline {...args} />
  </Wrapper>
);

export const CompleteSplitAppealTask = Template.bind({});
CompleteSplitAppealTask.args = {
  appeal: {
    ...splitAppeal
  },
  tasks: [splitAppealTask],
  queue: {
    amaTasks: {
      [splitAppealTask.uniqueId]: splitAppealTask
    }
  }
};
