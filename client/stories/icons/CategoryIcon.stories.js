import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { CategoryIcon } from '../../app/components/icons/CategoryIcon';

export default {
  title: 'Commons/Components/Icons/CategoryIcon',
  component: CategoryIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    className: { control: { type: 'text' } }
  },
  args: {
    color: COLORS.WHITE,
    size: '20px',
    className: ''
  }
};

const Template = (args) => <CategoryIcon {...args} />;

export const WhiteCategoryIcon = Template.bind({});
WhiteCategoryIcon.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];

export const ColorCategoryIcon = Template.bind({});
ColorCategoryIcon.decorators = [(Story) => <div style={{ padding: '20px' }}><Story /></div>];
ColorCategoryIcon.args = { color: '#333' };

