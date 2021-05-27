import React from 'react';

import { HearingDateDropdown } from './HearingDate';

/* eslint-disable react/prop-types */

export default {
  title: 'Commons/Components/Data Dropdowns/Hearing Date Dropdown',
  component: HearingDateDropdown,
  parameters: {
    controls: { expanded: true },
  },
  args: {
  },
  argTypes: {
  },
};

const Template = (args) => <HearingDateDropdown {...args} />;

export const Default = Template.bind({});
Default.args = { type: 'success' };
