import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { RightChevronIcon } from '../../app/components/icons/RightChevronIcon';

export default {
  title: 'Commons/Components/Icons/RightChevronIcon',
  component: RightChevronIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    color: { control: { type: 'color' } },
    size: { control: { type: 'number' } },
    cname: { control: { type: 'text' } }
  },
  args: {
    color: COLORS.WHITE,
    size: 17,
    cname: 'fa-chevron-left'
  }
};

const Template = (args) => <RightChevronIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
