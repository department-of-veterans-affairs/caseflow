import React from 'react';
import { MemoryRouter } from 'react-router';

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
  <table>
    <tbody>
      <tr>
        <StaticLever key={levers[2].item} {...args} lever={levers[2]} />
      </tr>
    </tbody>
  </table>
);

export const StaticLever4 = (args) => (
  <table>
    <tbody>
      <tr>
        <StaticLever key={levers[3].item} {...args} lever={levers[3]} />
      </tr>
    </tbody>
  </table>
);

export const StaticLever6 = (args) => (
  <table>
    <tbody>
      <tr>
        <StaticLever key={levers[5].item} {...args} lever={levers[5]} />
      </tr>
    </tbody>
  </table>
);

export const StaticLever8 = (args) => (
  <table>
    <tbody>
      <tr>
        <StaticLever key={levers[7].item} {...args} lever={levers[7]} />
      </tr>
    </tbody>
  </table>
);

