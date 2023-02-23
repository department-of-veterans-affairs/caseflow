import React from 'react';
import VhaHelp from './VhaHelp';
import ReduxBase from 'app/components/ReduxBase';
import helpReducers from '../../../app/help/helpApiSlice';

const ReduxDecorator = (Story) => (
  <ReduxBase reducer={helpReducers}>
    <Story />
  </ReduxBase>
);

export default {
  title: 'Help/Vha/Vha Help Page',
  component: VhaHelp,
  decorators: [ReduxDecorator],
  parameters: {},
  args: {},
  argTypes: {
  },
};

const Template = (args) => {
  return <VhaHelp {...args} />;
};

export const vhaForm = Template.bind({});
