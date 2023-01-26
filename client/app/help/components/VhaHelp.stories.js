import React from 'react';
import VhaHelp from './VhaHelp';
import ReduxBase from 'app/components/ReduxBase';

export default {
  title: 'Help/Vha/Vha Help Page',
  component: VhaHelp,
  decorators: [],
  parameters: {},
  args: {},
  argTypes: {
  },
};

const Template = (args) => {
  return <VhaHelp {...args} />;
};

export const vhaForm = Template.bind({});
