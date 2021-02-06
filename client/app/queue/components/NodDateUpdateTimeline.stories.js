import React from 'react';

import { NodDateUpdateTimeline } from './NodDateUpdateTimeline';

export default {
  title: 'Queue/CaseTimeline/NODDateUpdateTimeline',
  component: NodDateUpdateTimeline,
  parameters: {
    docs: {
      inlineStories: false
    },
  },
  args: {
    nodDateUpdate: {
      changeReason: 'entry_error',
      newDate: '2021-01-12',
      oldDate: '2021-01-05',
      updatedAt: '2021-01-25T15:10:29.033-05:00',
      userFirstName: 'Jane',
      userLastName: 'Doe'
    },
    timeline: true
  }
};

const Template = (args) => (
  <table>
    <tbody>
      <NodDateUpdateTimeline {...args} />
    </tbody>
  </table>
);

export const NODDateUpdateTimeline = Template.bind({});

