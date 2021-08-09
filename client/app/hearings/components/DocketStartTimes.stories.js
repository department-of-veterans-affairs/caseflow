import React from 'react';

import { DocketStartTimes } from './DocketStartTimes';

export default {
  title: 'Hearings/Components/Add Hearing Day/ Docket Start Times',
  component: DocketStartTimes,
  argTypes: {
    roTimezone: { control: { type: 'text' } }
  },
};

const Template = (args) => (
  <DocketStartTimes {...args}>
  </DocketStartTimes >
);
export const Default = Template.bind({});
Default.args = {
  roTimezone: 'America/Los_Angeles',
  hearingStartTime: null,
  setSlotCount: () => {},
  setHearingStartTime: () => {}
}

