import React from 'react';

import { PulacCerulloReminderAlert } from './PulacCerulloReminderAlert';

export default {
  title: 'Queue/Motions to Vacate/PulacCerulloReminderAlert',
  component: PulacCerulloReminderAlert,
  decorators: []
};

export const Basic = (args) => <PulacCerulloReminderAlert {...args} />;

Basic.parameters = {
  docs: {
    storyDescription: 'This provides a reminder for a user to check CAVC for a conflict of juristiction'
  }
};
