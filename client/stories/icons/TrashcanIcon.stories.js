import React from 'react';
import { TrashcanIcon } from '../../app/components/icons/TrashcanIcon';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';

export default {
  title: 'Commons/Components/Icons/TrashcanIcon',
  component: TrashcanIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    size: { control: { type: 'number' } },
    color: { control: { type: 'color' } },
    strokeColor: { control: { type: 'color' } },
    className: { control: { type: 'text' } }
  },
  args: {
    size: ICON_SIZES.MEDIUM,
    color: COLORS.WHITE,
    strokeColor: COLORS.PRIMARY,
    className: ''
  }
};

const Template = (args) => <TrashcanIcon {...args} />;

export const Default = Template.bind({});
