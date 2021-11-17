import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { ExternalLinkIcon } from '../../app/components/icons/ExternalLinkIcon';

export default {
  title: 'Commons/Components/Icons/ExternalLinkIcon',
  component: ExternalLinkIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    size: { control: { type: 'number' } },
    color: { control: { type: 'color' } },
    cname: { control: { type: 'text' } }
  },
  args: {
    size: 16,
    color: COLORS.WHITE,
    cname: ''
  }
};

const Template = (args) => <ExternalLinkIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
