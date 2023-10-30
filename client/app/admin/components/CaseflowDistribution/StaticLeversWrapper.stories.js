import React from 'react';
import { MemoryRouter } from 'react-router';

import StaticLeversWrapper from './StaticLeversWrapper';

import { levers } from 'test/data/adminCaseDistributionLevers';

const RouterDecorator = (Story) => (
  <MemoryRouter initialEntries={['/']}>
    <Story />
  </MemoryRouter>
);

export default {
  title: 'Admin/Caseflow Distribution/Static Levers',
  component: StaticLeversWrapper,
  decorators: [RouterDecorator]
};

// const Template = (args) => <StaticLever {...args} />;

export const StaticLever3 = (args) => (
  <table>
    <tbody>
      <tr>
        <StaticLeversWrapper key={levers[2].item} {...args} lever={levers[2]} />
      </tr>
    </tbody>
  </table>
);
