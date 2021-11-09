import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { ArrowDown } from '../../app/components/icons/ArrowDown';

export default {
  title: 'Commons/Components/Icons/ArrowDown',
  component: ArrowDown,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    cname: { control: { type: 'text' } }
  },
  args: {
    color: COLORS.GREY_DARK,
    size: 17,
    cname: ''
  }
};

const Template = (args) => <ArrowDown {...args} />;

export const Default = Template.bind({});
