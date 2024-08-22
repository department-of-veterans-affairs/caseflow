import React from 'react';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';
import { ArrowRightIcon } from '../../app/components/icons/ArrowRightIcon';

const config =  {
  title: 'Commons/Components/Icons/ArrowRightIcon',
  component: ArrowRightIcon,
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
    color: COLORS.GREY_DARK,
    className: ''
  }
};

const Template = (args) => <ArrowRightIcon {...args} />;
const Default = Template.bind({});
Template.args = { ...config.args, name: 'template' };
Template.argTypes = { ...config.argTypes, name: 'template' };
export default {
  component: Default,
};