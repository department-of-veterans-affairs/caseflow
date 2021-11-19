import React from 'react';
import { GrayDotIcon } from '../../app/components/icons/GrayDotIcon';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';

export default {
  title: 'Commons/Components/Icons/GrayDotIcon',
  component: GrayDotIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    size: { control: { type: 'number' } },
    color: { control: { type: 'color' } },
    className: { control: { type: 'text' } },
    strokeColor: { control: { type: 'color' } }
  },
  args: {
    size: ICON_SIZES.MEDIUM,
    color: COLORS.GREY,
    className: 'gray-dot',
    strokeColor: COLORS.WHITE
  }
};

const Template = (args) => <GrayDotIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
