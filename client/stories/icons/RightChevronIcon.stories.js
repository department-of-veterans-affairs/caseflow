import React from 'react';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';
import { RightChevronIcon } from '../../app/components/icons/RightChevronIcon';

export default {
  title: 'Commons/Components/Icons/RightChevronIcon',
  component: RightChevronIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    className: { control: { type: 'text' } }
  },
  args: {
    size: ICON_SIZES.SMALL,
    color: COLORS.WHITE,
    className: 'fa-chevron-left'
  }
};

const Template = (args) => <RightChevronIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
