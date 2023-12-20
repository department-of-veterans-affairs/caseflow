import React from 'react';
import { MemoryRouter } from 'react-router';
import { createJudgeTeam, createDvcTeam, createVso } from 'test/data/teamManagement';

import { TeamManagement } from './TeamManagement';

const judgeTeams = createJudgeTeam(5);
const dvcTeams = createDvcTeam(3);
const vsos = createVso(3);
const privateBars = createVso(3);

const RouterDecorator = (Story) => (
  <MemoryRouter initialEntries={['/']}>
    <Story />
  </MemoryRouter>
);

export default {
  title: 'Admin/Team Management/TeamManagement',
  component: TeamManagement,
  decorators: [RouterDecorator],
  args: {
    loadingPromise: () => new Promise((resolve) => resolve()),
    judgeTeams,
    dvcTeams,
    vsos,
    privateBars
  },
  argTypes: {
    onAddJudgeTeam: { action: 'onAddJudgeTeam' },
    onAddDvcTeam: { action: 'onAddDvcTeam' },
    onAddIhpWritingVso: { action: 'onAddIhpWritingVso' },
    onAddPrivateBar: { action: 'onAddPrivateBar' },
    onLookupParticipantId: { action: 'onLookupParticipantId' },
    onOrgUpdate: { action: 'update' }
  }
};

const Template = (args) => <TeamManagement {...args} />;

export const Default = Template.bind({});

export const Loading = Template.bind({});
Loading.args = {
  loadingPromise: () => new Promise(() => {})
};
