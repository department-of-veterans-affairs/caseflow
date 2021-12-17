import React from 'react';
import { NewFileIcon } from '../../app/components/icons/NewFileIcon';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';

export default {
  title: 'Commons/Components/Icons/NewFileIcon',
  component: NewFileIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    className: { control: { type: 'text' } }
  },
  args: {
    size: ICON_SIZES.XSMALL,
    color: COLORS.PURPLE,
    className: ''
  }
};

const Template = (args) => <NewFileIcon {...args} />;

export const Default = Template.bind({});
