import React from 'react';
import VhaMembershipRequestForm from './VhaMembershipRequestForm';
import ReduxBase from 'app/components/ReduxBase';
import helpReducers from '../../../app/help/helpApiSlice';

const ReduxDecorator = (Story) => (
  <ReduxBase reducer={helpReducers}>
    <Story />
  </ReduxBase>
);

export default {
  title: 'Help/Vha/VHA Membership Request Form',
  component: VhaMembershipRequestForm,
  decorators: [ReduxDecorator],
  parameters: {},
  args: {},
  argTypes: {
  },
};

const Template = (args) => {
  return <VhaMembershipRequestForm {...args} />;
};

export const Basic = Template.bind({});
