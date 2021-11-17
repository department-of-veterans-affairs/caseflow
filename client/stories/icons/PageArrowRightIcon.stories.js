import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { PageArrowRightIcon } from '../../app/components/icons/PageArrowRightIcon';

export default {
  title: 'Commons/Components/Icons/PageArrowRightIcon',
  component: PageArrowRightIcon,
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
    size: 20,
    cname: ''
  }
};

const Template = (args) => <PageArrowRightIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
