import React from 'react';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';
import { FitToScreenIcon } from '../../app/components/icons/FitToScreenIcon';

export default {
  title: 'Commons/Components/Icons/FitToScreenIcon',
  component: FitToScreenIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    size: { control: { type: 'number' } },
    color: { control: { type: 'color' } },
    className: { control: { type: 'text' } }
  },
  args: {
    size: ICON_SIZES.MEDIUM,
    color: COLORS.WHITE,
    className: ''
  }
};

const Template = (args) => <FitToScreenIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
