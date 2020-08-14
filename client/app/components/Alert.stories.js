import React from 'react';

import Alert from './Alert';

/* eslint-disable react/prop-types */

const alertTypes = ['success', 'error', 'warning', 'info'];

export default {
  title: 'Commons/Components/Alert',
  component: Alert,
  parameters: {
    controls: { expanded: true },
  },
  args: {
    message: 'This is the message of the alert',
    title: 'Sample Alert',
    type: 'success',
  },
  argTypes: {
    type: {
      control: { type: 'select', options: alertTypes },
    },
    styling: { control: { type: 'object' } },
  },
};

const Template = (args) => <Alert {...args} />;

export const Success = Template.bind({});
Success.args = { type: 'success' };

export const Error = Template.bind({});
Error.args = { type: 'error' };

export const Warning = Template.bind({});
Warning.args = { type: 'warning' };

export const Info = Template.bind({});
Info.args = { type: 'info' };

export const Slim = Template.bind({});
Slim.args = { title: '' };

Slim.parameters = {
  docs: {
    storyDescription: 'The "slim" alert will be used if title prop is empty',
  },
};
