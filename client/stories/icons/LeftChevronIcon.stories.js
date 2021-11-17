import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { LeftChevronIcon } from '../../app/components/icons/LeftChevronIcon';

export default {
  title: 'Commons/Components/Icons/LeftChevronIcon',
  component: LeftChevronIcon,
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

const Template = (args) => <LeftChevronIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
