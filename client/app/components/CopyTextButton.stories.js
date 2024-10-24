import React from 'react';

import CopyTextButton from './CopyTextButton';

export default {
  title: 'Commons/Components/CopyTextButton',
  component: CopyTextButton,
  decorators: [],
  args: {
    text: 'Lorem ipsum',
    textToCopy: 'Lorem ipsum',
    label: 'accessible label text'
  }
};

const Template = (args) => <CopyTextButton {...args} />;

export const Default = Template.bind({});

export const customTextToCopy = Template.bind({});
customTextToCopy.args = { textToCopy: 'I am custom text' };
