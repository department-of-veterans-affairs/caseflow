import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { ArrowLeftIcon } from '../../app/components/icons/ArrowLeftIcon';

export default {
  title: 'Commons/Components/Icons/ArrowLeftIcon',
  component: ArrowLeftIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    className: { control: { type: 'text' } }
  },
  args: {
    color: COLORS.GREY_DARK,
    size: 17,
    className: ''
  }
};

const Template = (args) => <ArrowLeftIcon {...args} />;

export const Default = Template.bind({});
