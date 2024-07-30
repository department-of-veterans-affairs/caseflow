import React from 'react';
import { SelectedFilterIcon } from '../../app/components/icons/SelectedFilterIcon';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';

export default {
  title: 'Commons/Components/Icons/SelectedFilterIcon',
  component: SelectedFilterIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    strokeColor: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
  },
  args: {
    color: COLORS.WHITE,
    strokeColor: COLORS.PRIMARY,
    size: ICON_SIZES.MEDIUM
  }
};

const Template = (args) => <SelectedFilterIcon {...args} />;

export const Default = Template.bind({});
Default.parameters = {
  docs: {
    description: {
      component: 'Used with the FilterIcon component.',
    },
  },
};
