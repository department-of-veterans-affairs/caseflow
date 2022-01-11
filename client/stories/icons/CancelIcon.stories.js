import React from 'react';
import { CancelIcon } from '../../app/components/icons/CancelIcon';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';

export default {
  title: 'Commons/Components/Icons/CancelIcon',
  component: CancelIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    size: { control: { type: 'number' } },
    color: { control: { type: 'color' } },
    className: { control: { type: 'text' } },
    bgColor: { control: { type: 'color' } }
  },
  args: {
    size: ICON_SIZES.LARGE,
    color: COLORS.RED,
    className: '',
    bgColor: COLORS.WHITE
  }
};

const Template = (args) => <CancelIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
