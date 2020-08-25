import React from 'react';

import { withKnobs, text } from '@storybook/addon-knobs';

import CopyTextButton from './CopyTextButton';

export default {
  title: 'Commons/Components/CopyTextButton',
  component: CopyTextButton,
  decorators: [withKnobs],
  args: {
    text: 'Lorem ipsum',
    label: 'accessible label text'
  }
};

const Template = (args) => <CopyTextButton {...args} />;

export const Default = Template.bind({});

export const customTextToCopy = Template.bind({});
customTextToCopy.args = { textToCopy: 'I am custom text' };
