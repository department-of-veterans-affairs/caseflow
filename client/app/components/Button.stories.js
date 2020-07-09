import React from 'react';

import Button from './Button';

export default {
  title: 'Commons/Components/Button',
  component: Button,
  parameters: {
    controls: { expanded: true },
  },
  args: {
    children: 'Click Me',
    disabled: false,
    linkStyling: false,
    loading: false,
    type: 'button',
    name: 'myButton',
  },
  argTypes: {
    classNames: { control: { type: 'array' } },
    type: {
      control: { type: 'select', options: ['button', 'submit', 'reset'] },
    },
    loading: { control: { type: 'boolean' } },
    onClick: { action: 'clicked' },
    styling: { control: { type: 'object' } },
  },
};

const Template = (args) => <Button {...args} />;

export const Primary = Template.bind({});

export const Secondary = Template.bind({});
Secondary.args = {
  classNames: ['usa-button-secondary'],
};

export const Link = Template.bind({});
Link.args = {
  linkStyling: true,
};

export const Disabled = Template.bind({});
Disabled.args = {
  disabled: true,
};

export const Loading = Template.bind({});
Loading.args = {
  name: 'loading',
  loading: true,
  loadingText: 'Loading...',
};
