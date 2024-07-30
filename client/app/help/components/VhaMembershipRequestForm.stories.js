import React, { useEffect } from 'react';
import VhaMembershipRequestForm from './VhaMembershipRequestForm';
import ReduxBase from 'app/components/ReduxBase';
import helpReducers, { setFeatureToggles, setUserOrganizations } from '../../../app/help/helpApiSlice';
import { useDispatch } from 'react-redux';

const ReduxDecorator = (Story) => (
  <ReduxBase reducer={helpReducers}>
    <Story />
  </ReduxBase>
);

export default {
  title: 'Help/VHA/VHA Membership Request Form',
  component: VhaMembershipRequestForm,
  decorators: [ReduxDecorator],
  parameters: {},
  args: {
    featureToggles: {}
  },
  argTypes: {
  },
};

const Template = (args) => {
  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(setFeatureToggles(args.featureToggles));
  }, [args.featureToggles]);

  useEffect(() => {
    dispatch(setUserOrganizations(args.organizations));
  }, [args.organizations]);

  return <VhaMembershipRequestForm {...args} />;
};

export const Basic = Template.bind({});

export const ProgramOfficeFeatureToggle = Template.bind({});
ProgramOfficeFeatureToggle.args = {
  featureToggles: {
    programOfficeTeamManagement: true
  }
};

export const WithDisabledOptions = Template.bind({});
WithDisabledOptions.args = {
  organizations: [{ name: 'VHA CAMO' }]
};
