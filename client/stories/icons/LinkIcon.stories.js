import React from 'react';
import { LinkIcon } from '../../app/components/icons/LinkIcon';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';

export default {
  title: 'Commons/Components/Icons/LinkIcon',
  component: LinkIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    size: { control: { type: 'number' } },
    leftColor: { control: { type: 'color' } },
    rightColor: { control: { type: 'color' } },
    className: { control: { type: 'text' } },
  },
  args: {
    size: ICON_SIZES.XSMALL,
    leftColor: COLORS.BASE,
    rightColor: COLORS.BASE,
    className: ''
  }
};

const Template = (args) => <LinkIcon {...args} />;

export const Default = Template.bind({});
