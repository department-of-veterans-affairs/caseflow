import React from 'react';

import { CheckoutButtons } from './CheckoutButtons';

export default {
  title: 'Queue/Docket Switch/CheckoutButtons',
  component: CheckoutButtons,
  decorators: [],
  parameters: {},
  args: {},
  argTypes: {
    onBack: { action: 'back' },
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => <CheckoutButtons {...args} />;

export const Basic = Template.bind({});

export const NoBack = Template.bind({});
NoBack.args = {
  // eslint-disable-next-line no-undefined
  onBack: undefined,
};

Basic.parameters = {
  docs: {
    storyDescription: 'Used in attorney checkout flow',
  },
};
