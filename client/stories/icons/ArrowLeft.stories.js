import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { ArrowLeft } from '../../app/components/icons/ArrowLeft';

export default {
  title: 'Commons/Components/Icons/ArrowLeft',
  component: ArrowLeft,
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

const Template = (args) => <ArrowLeft {...args} />;

export const Default = Template.bind({});
