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

export const StaticLever3 = (args) => (

  <>
    <StaticLever key={levers[3].item} {...args} lever={levers[3]} />
  </>
);
export const StaticLever4 = (args) => (

  <>
    <StaticLever key={levers[4].item} {...args} lever={levers[4]} />
  </>
);
export const StaticLever6 = (args) => (

  <>
    <StaticLever key={levers[6].item} {...args} lever={levers[6]} />
  </>
);
export const StaticLever8 = (args) => (

  <>
    <StaticLever key={levers[8].item} {...args} lever={levers[8]} />
  </>
);

