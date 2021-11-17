import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { SortArrowDownIcon } from '../../app/components/icons/SortArrowDownIcon';

export default {
  title: 'Commons/Components/Icons/SortArrowDownIcon',
  component: SortArrowDownIcon,
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
    cname: 'cf-sort-arrowdown table-icon'
  }
};

const Template = (args) => <SortArrowDownIcon {...args} />;

export const Default = Template.bind({});
