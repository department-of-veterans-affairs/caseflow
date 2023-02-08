import React from 'react';
import MembershipRequestTable from './MembershipRequestTable';
import { mockedMembershipRequests } from '../../test/data/membershipRequests';

export default {
  title: 'Admin/Team Management/Membership Requests',
  component: MembershipRequestTable,
  decorators: [],
  parameters: {},
  args: { requests: mockedMembershipRequests },
  argTypes: {
  },
};

const Template = (args) => {
  return <MembershipRequestTable {...args} />;
};

export const Basic = Template.bind({});
