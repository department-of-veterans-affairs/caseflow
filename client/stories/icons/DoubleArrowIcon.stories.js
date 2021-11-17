import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { DoubleArrowIcon } from '../../app/components/icons/DoubleArrowIcon';

export default {
  title: 'Commons/Components/Icons/DoubleArrowIcon',
  component: DoubleArrowIcon,
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

const Template = (args) => <DoubleArrowIcon {...args} />;

export const Default = Template.bind({});
