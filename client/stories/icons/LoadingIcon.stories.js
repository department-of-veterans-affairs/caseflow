import React from 'react';
import { LOGO_COLORS } from '../../app/constants/AppConstants';
import { LoadingIcon } from '../../app/components/icons/LoadingIcon';

export default {
  title: 'Commons/Components/Icons/LoadingIcon',
  component: LoadingIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    cname: { control: { type: 'text' } },
    text: { control: { type: 'text' } }
  },
  args: {
    text: '',
    size: '30px',
    color: LOGO_COLORS.DISPATCH.ACCENT,
    cname: 'cf-loading-button-symbol cf-small-loader-symbol'
  }
};

const Template = (args) => <LoadingIcon {...args} />;

export const Default = Template.bind({});

export const WithText = Template.bind({});
WithText.args = { text: 'loading...' };

export const Large = Template.bind({});
Large.args = { size: '150px' };
