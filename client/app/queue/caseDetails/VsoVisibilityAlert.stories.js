import React from 'react';

import { VsoVisibilityAlert } from './VsoVisibilityAlert';

export default {
  title: 'Queue/Case Details/VsoVisibilityAlert',
  component: VsoVisibilityAlert,
};

const Template = (args) => <VsoVisibilityAlert {...args} />;

export const Default = Template.bind({});
