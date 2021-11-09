import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { DoubleArrow } from '../../app/components/icons/DoubleArrow';

export default {
  title: 'Commons/Components/Icons/DoubleArrow',
  component: DoubleArrow,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    topColor: { control: { type: 'color' } },
    bottomColor: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    cname: { control: { type: 'text' } }
  },
  args: {
    topColor: COLORS.GREY_DARK,
    bottomColor: COLORS.GREY_DARK,
    size: 16,
    cname: 'table-icon'
  }
};

const Template = (args) => <DoubleArrow {...args} />;

export const Default = Template.bind({});
