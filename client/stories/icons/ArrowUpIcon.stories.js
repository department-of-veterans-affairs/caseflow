import React from 'react';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';
import { ArrowUpIcon } from '../../app/components/icons/ArrowUpIcon';

const config = {
  title: 'Commons/Components/Icons/ArrowUpIcon',
  component: ArrowUpIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    className: { control: { type: 'text' } },
    title: { control: { type: 'text' } }
  },
  args: {
    size: ICON_SIZES.SMALL,
    color: COLORS.GREY_DARK,
    className: ''
  }
};

const Template = (args) => <ArrowUpIcon {...args} />;
Template.args = { ...config.args, name: 'template' };
Template.argTypes = { ...config.argTypes, name: 'template' };

const Default = Template.bind({});
export default {
  component: Default,
};