import React from 'react';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';
import { PageArrowLeftIcon } from '../../app/components/icons/PageArrowLeftIcon';

export default {
  title: 'Commons/Components/Icons/PageArrowLeftIcon',
  component: PageArrowLeftIcon,
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
    size: ICON_SIZES.SMALL,
    className: ''
  }
};

const Template = (args) => <PageArrowLeftIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
