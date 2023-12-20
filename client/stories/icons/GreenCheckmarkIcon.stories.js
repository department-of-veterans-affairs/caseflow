import React from 'react';
import { GreenCheckmarkIcon } from '../../app/components/icons/GreenCheckmarkIcon';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';

export default {
  title: 'Commons/Components/Icons/GreenCheckmarkIcon',
  component: GreenCheckmarkIcon,
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
    size: ICON_SIZES.LARGE,
    strokeColor: COLORS.WHITE,
    color: COLORS.GREEN,
    className: 'green-checkmark'
  }
};

const Template = (args) => <GreenCheckmarkIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
