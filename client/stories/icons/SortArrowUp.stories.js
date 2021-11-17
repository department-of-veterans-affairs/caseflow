import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { SortArrowUp } from '../../app/components/icons/SortArrowUp';

export default {
  title: 'Commons/Components/Icons/SortArrowUp',
  component: SortArrowUp,
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

const Template = (args) => <SortArrowUp {...args} />;

export const Default = Template.bind({});
