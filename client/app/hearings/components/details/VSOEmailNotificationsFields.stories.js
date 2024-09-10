import React from 'react';

import { VSOEmailNotificationsFields } from './VSOEmailNotificationsFields';

export default {
  title: 'Hearings/Components/VSOEmailNotificationFields',
  component: VSOEmailNotificationsFields
};

const Template = (args) => (
  <VSOEmailNotificationsFields {...args} />
);

export const Basic = () => Template.bind({});
Basic.args = {
  hearing: {
    appellantEmailAddress: 'appellant@test.com',
    appellantTz: 'America/New_York',
    scheduledTimeString: '1:00 PM Eastern Time (US & Canada)',
    appellantIsNotVeteran: false,
    scheduledForIsPast: false,
    isVirtual: false
  },
  update: () => 'updated',
  setIsValidEmail: true,
  actionType: 'test',
  errors: [],
  hearingDayDate: '2024-08-20'
};
