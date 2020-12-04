import React from 'react';
import IhpDaysWaitingTooltip from './IhpDaysWaitingTooltip';

export default {
  title: 'queue/Components/IhpDaysWaitingTooltip',
  component: IhpDaysWaitingTooltip,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    requestedAt: { control: { type: 'text' } },
    receivedAt: { control: { type: 'text' } },
  },
};

const Template = (args) => <IhpDaysWaitingTooltip {...args}>
  <div style={{ textAlign: 'center' }}><span>3 days (hover over me)</span></div>
</IhpDaysWaitingTooltip>;

export const WaitingForIHP = Template.bind({});
WaitingForIHP.args = { requestedAt: '2020-10-03T13:39:36.574-05:00', receivedAt: null };

export const ReceivedIHP = Template.bind({});
ReceivedIHP.args = { requestedAt: '2020-10-03T13:39:36.574-05:00', receivedAt: '2020-11-03T13:39:36.574-05:00' };
