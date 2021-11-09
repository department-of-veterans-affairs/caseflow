import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { MagnifyingGlass } from '../../app/components/icons/MagnifyingGlass';

export default {
  title: 'Commons/Components/Icons/MagnifyingGlass',
  component: MagnifyingGlass,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    cname: { control: { type: 'text' } }
  },
  args: {
    color: COLORS.GREY_MEDIUM,
    size: 24,
    cname: ''
  }
};

const Template = (args) => <MagnifyingGlass {...args} />;

export const Default = Template.bind({});
