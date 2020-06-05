import React from 'react';

import Button from './Button';

export default {
  title: 'Commons/Components/Button',
  component: Button,
  parameters: {
    controls: { expanded: true }
  },
  args: {
    children: 'Click Me',
    type: 'button',
    name: 'myButton',
    loading: false
  },
  argTypes: {
    classNames: { control: { type: 'array' } },
    type: { control: { type: 'select', options: ['button', 'submit', 'reset'] } },
    loading: { control: { type: 'boolean' } },
    onClick: { action: 'clicked' },
    styling: { control: { type: 'object' } }
  }
};

export const Default = (args) => <Button {...args} />;

export const primary = (args) => <Button {...args} />;

export const secondary = (args) => <Button {...args} classNames={['usa-button-secondary']} />;
secondary.args = {
  classNames: ['usa-button-secondary']
};

export const link = (args) => <Button {...args} />;
link.args = {
  linkStyling: true
};

export const disabled = (args) => <Button {...args} disabled />;
disabled.args = {
  disabled: true
};

export const loading = (args) => <Button {...args} loading loadingText="Loading..." />;
loading.args = {
  name: 'loading',
  loading: true
};
