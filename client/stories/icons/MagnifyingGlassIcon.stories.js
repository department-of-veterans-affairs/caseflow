import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { MagnifyingGlassIcon } from '../../app/components/icons/MagnifyingGlassIcon';

export default {
  title: 'Commons/Components/Icons/MagnifyingGlassIcon',
  component: MagnifyingGlassIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    className: { control: { type: 'text' } }
  },
  args: {
    color: COLORS.GREY_MEDIUM,
    size: 24,
    className: ''
  }
};

const Template = (args) => <MagnifyingGlassIcon {...args} />;

export const Default = Template.bind({});
