import React from 'react';

import SaveableTextArea from './SaveableTextArea';

export default {
  title: 'Commons/Components/Form Fields/SaveableTextArea',
  component: SaveableTextArea,
  parameters: {
    controls: { expanded: true },
  },
  args: {
    disabled: false,
    hideLabel: false,
    label: 'Label'
  },
  argTypes: {
    disabled: { control: { type: 'boolean' } },
    hideLabel: { control: { type: 'boolean' } },
    label: { control: { type: 'text' } }
  }
};

const Template = (args) => <SaveableTextArea {...args} />;

export const Default = Template.bind({});

export const Disabled = Template.bind({});
Disabled.args = { disabled: true };

export const HiddenLabel = Template.bind({});
HiddenLabel.args = { hideLabel: true };
