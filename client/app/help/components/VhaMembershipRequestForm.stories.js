import React from 'react';
import VhaMembershipRequestForm from './VhaMembershipRequestForm';
import ReduxBase from 'app/components/ReduxBase';

export default {
  title: 'Help/Vha/VHA Membership Request Form',
  component: VhaMembershipRequestForm,
  decorators: [],
  parameters: {},
  args: {},
  argTypes: {
  },
};

const Template = (args) => {
  return <VhaMembershipRequestForm {...args} />;
};

export const vhaForm = Template.bind({});
// AllIntakes.args = defaultArgs;
// VhaMembershipRequestForm.decorators = [FullReduxDecorator, RouterDecorator];
