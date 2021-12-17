import React from 'react';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';
import { PageArrowRightIcon } from '../../app/components/icons/PageArrowRightIcon';

export default {
  title: 'Commons/Components/Icons/PageArrowRightIcon',
  component: PageArrowRightIcon,
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
    size: ICON_SIZES.MEDIUM,
    className: ''
  }
};

const Template = (args) => <PageArrowRightIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
