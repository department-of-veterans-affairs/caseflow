import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { ArrowDownIcon } from '../../app/components/icons/ArrowDownIcon';

export default {
  title: 'Commons/Components/Icons/ArrowDownIcon',
  component: ArrowDownIcon,
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

const Template = (args) => <ArrowDownIcon {...args} />;

export const Default = Template.bind({});
