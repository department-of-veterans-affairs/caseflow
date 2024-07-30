import React from 'react';
import { queueWrapper as Wrapper } from '../../../test/data/stores/queueStore';
import Alert from '../../components/Alert';
import { SplitAppealBannerAlert } from './SplitAppealBannerAlert';

export default {
  title: 'Queue/Case Details/SplitAppealAlert',
  component: SplitAppealBannerAlert,
  args: {
    splitAppealSuccess: true,
    workflow: true,
  },
  argTypes: {
    splitAppealSuccess: { control: { type: 'boolean' } },
    workflow: { control: { type: 'boolean' } },
  }
};

const Template = (args) => <SplitAppealBannerAlert {...args} />;

export const SuccessBanner = Template.bind({});
SuccessBanner.args = {
  splitAppealSuccess: true,
  workflow: true,
};

export const ErrorBanner = Template.bind({});
ErrorBanner.args = {
  splitAppealSuccess: false,
  workflow: true,
};
