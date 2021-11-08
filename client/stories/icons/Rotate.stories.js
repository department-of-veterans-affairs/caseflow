import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { Rotate } from '../../app/components/icons/Rotate';

export default {
  title: 'Commons/Components/Icons/Rotate',
  component: Rotate,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    size: { control: { type: 'number' } },
    color: { control: { type: 'color' } },
    cname: { control: { type: 'text' } }
  },
  args: {
    size: 19,
    color: COLORS.WHITE,
    cname: ''
  }
};

const Template = (args) => <Rotate {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
