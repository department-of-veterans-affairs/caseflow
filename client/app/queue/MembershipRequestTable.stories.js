import React from 'react';
import MembershipRequestTable from './MembershipRequestTable';
import { mockedMembershipRequests, createMockedMembershipRequests } from '../../test/data/membershipRequests';

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

const PaginationTemplate = (args) => {
  args.requests = createMockedMembershipRequests(25);

  return <MembershipRequestTable {...args} />;
};

export const Pagination = PaginationTemplate.bind({});
