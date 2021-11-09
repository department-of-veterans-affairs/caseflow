import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { LockIcon } from '../../app/components/icons/LockIcon';

export default {
  title: 'Commons/Components/Icons/LockIcon',
  component: LockIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    size: { control: { type: 'number' } },
    color: { control: { type: 'color' } },
    cname: { control: { type: 'text' } }
  },
  args: {
    size: 18,
    color: COLORS.GREY_DARK,
    cname: 'cf-lock-icon'
  }
};

const Template = (args) => <LockIcon {...args} />;

export const Default = Template.bind({});
