import React from 'react';
import { FilterNoOutlineIcon } from '../../app/components/icons/FilterNoOutlineIcon';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';

export default {
  title: 'Commons/Components/Icons/FilterNoOutlineIcon',
  component: FilterNoOutlineIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    size: { control: { type: 'number' } },
    color: { control: { type: 'color' } },
    className: { control: { type: 'text' } }
  },
  args: {
    color: COLORS.WHITE,
    size: 14,
    className: 'filter-icon'
  }
};

const Template = (args) => <FilterNoOutlineIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];

