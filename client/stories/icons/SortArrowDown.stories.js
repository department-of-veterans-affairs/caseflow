import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { SortArrowDown } from '../../app/components/icons/SortArrowDown';

export default {
  title: 'Commons/Components/Icons/SortArrowDown',
  component: SortArrowDown,
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

const Template = (args) => <SortArrowDown {...args} />;

export const Default = Template.bind({});
