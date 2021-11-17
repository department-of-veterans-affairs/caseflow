import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { SortArrowUpIcon } from '../../app/components/icons/SortArrowUpIcon';

export default {
  title: 'Commons/Components/Icons/SortArrowUpIcon',
  component: SortArrowUpIcon,
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
    size: 10,
    cname: 'cf-sort-arrowup table-icon'
  }
};

const Template = (args) => <SortArrowUpIcon {...args} />;

export const Default = Template.bind({});
