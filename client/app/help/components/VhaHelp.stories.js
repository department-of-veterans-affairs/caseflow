import React, { useEffect } from 'react';
import VhaHelp from './VhaHelp';
import ReduxBase from 'app/components/ReduxBase';
import helpReducers, { setSuccessMessage, setErrorMessage } from '../../../app/help/helpApiSlice';
import { useDispatch } from 'react-redux';
import { sprintf } from 'sprintf-js';
import { VHA_MEMBERSHIP_REQUEST_FORM_SUBMIT_SUCCESS_MESSAGE } from '../../../COPY';

const ReduxDecorator = (Story) => (
  <ReduxBase reducer={helpReducers}>
    <Story />
  </ReduxBase>
);

export default {
  title: 'Help/VHA/VHA Help Page',
  component: VhaHelp,
  decorators: [ReduxDecorator],
  parameters: {},
  args: {},
  argTypes: {
  },
};

const Template = (args) => {
  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(setSuccessMessage(args.successMessage));
  }, [args.successMessage]);

  useEffect(() => {
    dispatch(setErrorMessage(args.errorMessage));
  }, [args.errorMessage]);

  return <VhaHelp {...args} />;
};

export const Basic = Template.bind({});

export const SuccessBanner = Template.bind({});

SuccessBanner.args = {
  successMessage: sprintf(VHA_MEMBERSHIP_REQUEST_FORM_SUBMIT_SUCCESS_MESSAGE, 'VHA group'),
};

export const ErrorBanner = Template.bind({});

ErrorBanner.args = {
  errorMessage: 'Emailing Error: Your account is missing an email address.',
};
