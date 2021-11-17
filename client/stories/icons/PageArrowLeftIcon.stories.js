import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { PageArrowLeftIcon } from '../../app/components/icons/PageArrowLeftIcon';

export default {
  title: 'Commons/Components/Icons/PageArrowLeftIcon',
  component: PageArrowLeftIcon,
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
    size: 17,
    className: ''
  }
};

const Template = (args) => <PageArrowLeftIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
