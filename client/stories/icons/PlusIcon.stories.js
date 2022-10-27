import React from 'react';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';
import { PlusIcon } from '../../app/components/icons/PlusIcon';

export default {
  title: 'Commons/Components/Icons/PlusIcon',
  component: PlusIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    className: { control: { type: 'text' } }
  },
  args: {
    color: COLORS.WHITE,
    size: ICON_SIZES.XSMALL,
    className: ''
  }
};

const Template = (args) => <PlusIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
