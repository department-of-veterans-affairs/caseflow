import React from 'react';

import { withKnobs, text, boolean, select, object } from '@storybook/addon-knobs';

import Alert from './Alert';

export default {
  title: 'Commons/Components/Alert',
  component: Alert,
  decorators: [withKnobs]
};

export const allOptions = () => (
  <Alert
    fixed={text('Fixed', '', 'allOptions')}
    lowerMargin={boolean('Lower Margin', false, 'allOptions')}
    message={text('Message', 'This is the message of the alert', 'allOptions')}
    title={text('Title', 'Sample Alert', 'allOptions')}
    type={select('Type', ['success', 'error', 'warning', 'info'], 'success', 'allOptions')}
    styling={object('Styling', {}, 'allOptions')}
    scrollOnAlert={boolean('Scroll on Alert', true)}
  >
    {text('Contents', '', 'allOptions')}
  </Alert>
);

export const success = () => (
  <Alert
    fixed={text('Fixed', '', 'success')}
    lowerMargin={boolean('Lower Margin', false, 'success')}
    message={text('Message', 'This is the message of the alert', 'success')}
    title={text('Title', 'Sample Alert', 'success')}
    type={select('Type', ['success', 'error', 'warning', 'info'], 'success', 'success')}
    styling={object('Styling', {}, 'success')}
    scrollOnAlert={boolean('Scroll on Alert', true)}
  >
    {text('Contents', '', 'success')}
  </Alert>
);

export const error = () => (
  <Alert
    fixed={text('Fixed', '', 'error')}
    lowerMargin={boolean('Lower Margin', false, 'error')}
    message={text('Message', 'This is the message of the alert', 'error')}
    title={text('Title', 'Sample Alert', 'error')}
    type={select('Type', ['success', 'error', 'warning', 'info'], 'error', 'error')}
    styling={object('Styling', {}, 'error')}
    scrollOnAlert={boolean('Scroll on Alert', true)}
  >
    {text('Contents', '', 'error')}
  </Alert>
);

export const warning = () => (
  <Alert
    fixed={text('Fixed', '', 'warning')}
    lowerMargin={boolean('Lower Margin', false, 'warning')}
    message={text('Message', 'This is the message of the alert', 'warning')}
    title={text('Title', 'Sample Alert', 'warning')}
    type={select('Type', ['success', 'error', 'warning', 'info'], 'warning', 'warning')}
    styling={object('Styling', {}, 'warning')}
    scrollOnAlert={boolean('Scroll on Alert', true)}
  >
    {text('Contents', '', 'warning')}
  </Alert>
);

export const info = () => (
  <Alert
    fixed={text('Fixed', '', 'info')}
    lowerMargin={boolean('Lower Margin', false, 'info')}
    message={text('Message', 'This is the message of the alert', 'info')}
    title={text('Title', 'Sample Alert', 'info')}
    type={select('Type', ['success', 'error', 'warning', 'info'], 'info', 'info')}
    styling={object('Styling', {}, 'info')}
    scrollOnAlert={boolean('Scroll on Alert', true)}
  >
    {text('Contents', '', 'info')}
  </Alert>
);

export const slim = () => (
  <Alert
    fixed={text('Fixed', '', 'slim')}
    lowerMargin={boolean('Lower Margin', false, 'slim')}
    message={text('Message', 'This is the message of the alert', 'slim')}
    title={text('Title', '', 'slim')}
    type={select('Type', ['success', 'error', 'warning', 'info'], 'success', 'slim')}
    styling={object('Styling', {}, 'slim')}
    scrollOnAlert={boolean('Scroll on Alert', true)}
  >
    {text('Contents', '', 'slim')}
  </Alert>
);

slim.parameters = {
  docs: {
    storyDescription: 'The "slim" alert will be used if title prop is empty'
  }
};
