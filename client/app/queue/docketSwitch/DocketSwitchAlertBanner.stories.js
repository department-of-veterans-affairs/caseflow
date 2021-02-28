import React from 'react';

import DocketSwitchAlertBanner from './DocketSwitchAlertBanner';

export default {
  title: 'Queue/Docket Switch/DocketSwitchAlertBanner',
  component: DocketSwitchAlertBanner,
  parameters: {},
  args: {
  	appeal: {
  		docketSwitch
  	},
  }
};

const Template = (args) => (
  <DocketSwitchAlertBanner {...args} />
);

export const DocketSwitchAlertBanner = Template.bind({});