import faker from 'faker';

// Example Membership Request data used for testing with no randomization
export const mockedMembershipRequests = [
  {
    id: 1,
    userNameWithCssId: 'John Doe',
    requestedDate: '2022-12-05',
    note: 'Please process this request as soon as possible'
  },
  {
    id: 2,
    userNameWithCssId: 'Jane Smith',
    requestedDate: '2022-11-27',
    note: 'This request can be postponed for now.'
  },
  {
    id: 3,
    userNameWithCssId: 'William Brown',
    requestedDate: '2022-12-01',
  },
  {
    id: 4,
    userNameWithCssId: 'Emma Wilson',
    requestedDate: '2022-11-20',
  },
  {
    id: 5,
    userNameWithCssId: 'Micheal Johnson',
    requestedDate: '2022-11-30'
  }
];

// Randomized membership request data
export const createMockedMembershipRequests = (number) => {
  const mockedRequests = [];

  for (let i = 0; i <= number; i++) {
    mockedRequests.push({
      id: i + 6,
      userNameWithCssId: faker.name.findName(),
      requestedDate: faker.date.recent(10),
      ...(Math.random() <= 0.3 && { note: faker.lorem.lines(1) }),
    });
  }

  return mockedRequests;
};
