import React from 'react';
import { PencilIcon } from '../../app/components/icons/PencilIcon';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';

export default {
  title: 'Commons/Components/Icons/PencilIcon',
  component: PencilIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    className: { control: { type: 'text' } }
  },
  args: {
    size: ICON_SIZES.MEDIUM,
    color: COLORS.PRIMARY,
    className: ''
  }
};

const Template = (args) => <PencilIcon {...args} />;

export const Default = Template.bind({});
