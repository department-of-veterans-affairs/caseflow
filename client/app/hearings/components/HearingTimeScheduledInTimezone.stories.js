import React from 'react';

import { virtualHearing } from '../../../test/data/hearings';

import { HearingTimeScheduledInTimezone } from './HearingTimeScheduledInTimezone';

export default {
  title: 'Hearings/Components/HearingTimeScheduledInTimezone',
  component: HearingTimeScheduledInTimezone,
  argTypes: {
  }
};

const defaultArgs = {
  showIssueCount: true,
  showRegionalOfficeName: true,
  showRequestType: true
};

const Template = (args) => {

  return (
    <HearingTimeScheduledInTimezone
      {...args}
      {...defaultArgs}
      hearing = {virtualHearing.virtualHearing}
    />

  );
};

export const Default = Template.bind({});
