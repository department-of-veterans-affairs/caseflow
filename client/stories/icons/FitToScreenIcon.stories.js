import React from 'react';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { FitToScreenIcon } from '../../app/components/icons/FitToScreenIcon';

export default {
  title: 'Commons/Components/Icons/FitToScreenIcon',
  component: FitToScreenIcon,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    size: { control: { type: 'number' } },
    color: { control: { type: 'color' } },
    className: { control: { type: 'text' } }
  },
  args: {
    size: 19,
    color: COLORS.WHITE,
    className: ''
  }
};

const Template = (args) => <FitToScreenIcon {...args} />;

export const Default = Template.bind({});
Default.decorators = [(Story) => <div style={{ padding: '20px', background: '#333' }}><Story /></div>];
