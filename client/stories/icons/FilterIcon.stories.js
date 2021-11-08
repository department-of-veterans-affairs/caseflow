import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { FilterIcon } from '../../app/components/icons/FilterIcon';

export default {
  title: 'Commons/Components/Icons/FilterIcon',
  component: FilterIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    size: { control: { type: 'number' } },
    color: { control: { type: 'color' } },
    cname: { control: { type: 'text' } }
  },
  args: {
    color: COLORS.WHITE,
    size: 14,
    cname: 'filter-icon'
  }
};

const Template = (args) => <FilterIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
