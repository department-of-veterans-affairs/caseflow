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

export const allOptions = ({
  fixed,
  lowerMargin,
  message,
  title,
  type,
  styling,
  scrollOnAlert,
}) => (
  <Alert
    fixed={fixed}
    lowerMargin={lowerMargin}
    message={message}
    title={title}
    type={type}
    styling={styling}
    scrollOnAlert={scrollOnAlert}
  />
);

export const success = ({ type, ...args }) => <Alert {...args} type={type} />;
success.args = { type: 'success' };

export const error = ({ type, ...args }) => <Alert {...args} type={type} />;
error.args = { type: 'error' };

export const warning = ({ type, ...args }) => <Alert {...args} type={type} />;
warning.args = { type: 'warning' };

export const info = ({ type, ...args }) => <Alert {...args} type={type} />;
info.args = { type: 'info' };

export const slim = ({ title, ...args }) => <Alert {...args} title={title} />;
slim.args = { title: '' };

slim.parameters = {
  docs: {
    storyDescription: 'The "slim" alert will be used if title prop is empty',
  },
};
