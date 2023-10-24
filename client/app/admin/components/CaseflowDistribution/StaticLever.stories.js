import React from 'react';
import { MemoryRouter } from 'react-router';
import { css } from 'glamor';

import StaticLever from './StaticLever';

import { levers } from 'test/data/adminCaseDistributionLevers';

const RouterDecorator = (Story) => (
  <MemoryRouter initialEntries={['/']}>
    <Story />
  </MemoryRouter>
);

export default {
  title: 'Admin/Caseflow Distribution/Static Levers',
  component: StaticLever,
  decorators: [RouterDecorator]
};

// const Template = (args) => <StaticLever {...args} />;

export const StaticLevers = (args) => (
  <>
    {levers.
      filter((lever) => !lever.is_active).
      map((lever, index) => (
        <StaticLever key={index} {...args} lever={lever} />
      ))}
  </>
);
// StaticLevers.args = {
//   lever: {
//     title: 'Sample Lever Title',
//     description: 'Sample Lever Description',
//     newValue: 42,
//     unit: 'units',
//   },
// };

