import React from 'react';
import CaseflowDistributionApp from './CaseflowDistributionApp';

import { MemoryRouter } from 'react-router';

const RouterDecorator = (Story) => (
  <MemoryRouter initialEntries={['/']}>
    <Story />
  </MemoryRouter>
);

export default {
  title: 'Admin/Caseflow Distribution/CaseflowDistributionApp',
  component: CaseflowDistributionApp,
  decorators: [RouterDecorator]
};

export const Primary = () =>
  <CaseflowDistributionApp
    param1 = {[]}
  />;

Primary.story = {
  name: 'Case Distribution App'
};

