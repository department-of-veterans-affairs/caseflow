import React from 'react';
import { UnselectedFilterIcon } from '../../app/components/icons/UnselectedFilterIcon';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';

export default {
  title: 'Commons/Components/Icons/UnselectedFilterIcon',
  component: UnselectedFilterIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    strokeColor: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    className: { control: { type: 'text' } }
  },
  args: {
    color: COLORS.WHITE,
    strokeColor: COLORS.BASE,
    size: ICON_SIZES.MEDIUM,
    className: '',
  }
};

const Template = (args) => <UnselectedFilterIcon {...args} />;

export const Default = Template.bind({});
Default.parameters = {
  docs: {
    description: {
      component: 'Used with the FilterIcon component.',
    },
  },
};
