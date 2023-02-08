import React from 'react';
import MembershipRequestTable from './MembershipRequestTable';

// Example Membership Request data used for testing
const mockedMembershipRequests = [
  {
    id: 1,
    name: 'John Doe',
    requestedDate: '2022-12-05',
    note: 'Please process this request as soon as possible'
  },
  {
    id: 2,
    name: 'Jane Smith',
    requestedDate: '2022-11-27',
    note: 'This request can be postponed for now.'
  },
  {
    id: 3,
    name: 'William Brown',
    requestedDate: '2022-12-01',
  },
  {
    id: 4,
    name: 'Emma Wilson',
    requestedDate: '2022-11-20',
  },
  {
    id: 5,
    name: 'Micheal Johnson',
    requestedDate: '2022-11-30'
  }
];

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
