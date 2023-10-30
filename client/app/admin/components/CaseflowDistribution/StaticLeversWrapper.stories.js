import React from 'react';
import { MemoryRouter } from 'react-router';

import StaticLeversWrapper from './StaticLeversWrapper';

// import { levers } from 'test/data/adminCaseDistributionLevers';
// import StaticLever from './StaticLever';

const RouterDecorator = (Story) => (
  <MemoryRouter initialEntries={['/']}>
    <Story />
  </MemoryRouter>
);

const leverList = ['lever_3', 'lever_2', 'lever_7'];

export default {
  title: 'Admin/Caseflow Distribution/Static Levers Wrapper',
  component: StaticLeversWrapper,
  decorators: [RouterDecorator]
};

// const Template = (args) => <StaticLever {...args} />;

export const StaticWrapper = () => (
  <table>
    <tbody>
      <tr>
        <StaticLeversWrapper leverList={leverList} />
      </tr>
    </tbody>
  </table>
);
