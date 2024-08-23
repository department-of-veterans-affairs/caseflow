import React from 'react';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';
import { DownloadIcon } from '../../app/components/icons/DownloadIcon';

const config =  {
  title: 'Commons/Components/Icons/DownloadIcon',
  component: DownloadIcon,
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

const Template = (args) => <DownloadIcon {...args} />;

const Default = Template.bind({});
Default.args = { ...config.args, name: 'default' };
Default.argTypes = { ...config.argTypes, name: 'default' };
export default {
  component: Default,
};
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
