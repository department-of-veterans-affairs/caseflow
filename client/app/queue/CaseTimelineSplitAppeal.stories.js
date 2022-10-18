import React from 'react';

import { CaseTimeline } from './CaseTimeline';

import { splitAppeal1 } from '../../test/data/appeals';
import { splitAppealTask } from '../../test/data/tasks';
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
  <Wrapper>
    <CaseTimeline {...args} />
  </Wrapper>
);

export const CompleteSplitAppealTask = Template.bind({});
CompleteSplitAppealTask.args = {
  appeal: {
    ...splitAppeal1
  },
  editNodDateEnabled: false,
  statusSplit: true,
  tasks: [splitAppealTask]
};
