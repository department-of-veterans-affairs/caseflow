import React from 'react';
import { ReaderCommentIcon } from '../../app/components/icons/ReaderCommentIcon';
import { ICON_SIZES, COLORS } from '../../app/constants/AppConstants';

export default {
  title: 'Commons/Components/Icons/ReaderCommentIcon',
  component: ReaderCommentIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    selected: { control: { type: 'boolean' } },
    id: { control: { type: 'range' }, options: [1, 3, 1] },
    size: { control: { type: 'number' } },
    className: { control: { type: 'text' } }
  },
  args: {
    color: COLORS.GOLD_LIGHT,
    selected: false,
    id: 1,
    size: ICON_SIZES.LARGE,
    classNameName: ''
  }
};

const Template = (args) => <ReaderCommentIcon {...args} />;

export const Default = Template.bind({});
