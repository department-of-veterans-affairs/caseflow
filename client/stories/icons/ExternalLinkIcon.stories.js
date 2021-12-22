import React from 'react';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';
import { ExternalLinkIcon } from '../../app/components/icons/ExternalLinkIcon';

export default {
  title: 'Commons/Components/Icons/ExternalLinkIcon',
  component: ExternalLinkIcon,
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

const Template = (args) => <ExternalLinkIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
