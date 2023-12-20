import React from 'react';

import { CaseTimeline } from './CaseTimeline';

import { legacyAppealForTravelBoard } from '../../test/data/appeals';
import { changeHearingRequestTypeTask } from '../../test/data/tasks';
import { queueWrapper as Wrapper } from '../../test/data/stores/queueStore';

export default {
  title: 'Queue/CaseTimeline',
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

export const CompletedChangeHearingRequestTypeTask = Template.bind({});
CompletedChangeHearingRequestTypeTask.args = {
  appeal: {
    ...legacyAppealForTravelBoard
  },
  tasks: [changeHearingRequestTypeTask]
};
