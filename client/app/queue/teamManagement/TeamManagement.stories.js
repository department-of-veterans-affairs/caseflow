import React from 'react';
import { createJudgeTeam, createDvcTeam, createVso } from 'test/data/teamManagement';

import { TeamManagement } from './TeamManagement';

const judgeTeams = createJudgeTeam(5);
const dvcTeams = createDvcTeam(3);
const vsos = createVso(3);

export default {
  title: 'Admin/Team Management/TeamManagement',
  component: TeamManagement,
  args: {
    loadingPromise: () => new Promise((resolve) => resolve()),
    judgeTeams,
    dvcTeams,
    vsos
  }
};

const Template = (args) => <TeamManagement {...args} />;

export const Default = Template.bind({});

export const Loading = Template.bind({});
Loading.args = {
  loadingPromise: () => new Promise(() => {})
};
