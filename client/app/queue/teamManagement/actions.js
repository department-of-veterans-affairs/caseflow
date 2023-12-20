// To-do: This file is deprecated and can likely be removed.
// It has been superceded by teamManagement.slice.js

import { ACTIONS } from './constants';

export const onReceiveNewJudgeTeam = (payload) => ({
  type: ACTIONS.ON_RECEIVE_NEW_JUDGE_TEAM,
  payload
});

export const onReceiveNewDvcTeam = (payload) => ({
  type: ACTIONS.ON_RECEIVE_NEW_DVC_TEAM,
  payload
});

export const onReceiveNewPrivateBar = (payload) => ({
  type: ACTIONS.ON_RECEIVE_NEW_PRIVATE_BAR,
  payload
});

export const onReceiveNewVso = (payload) => ({
  type: ACTIONS.ON_RECEIVE_NEW_VSO,
  payload
});

export const onReceiveTeamList = (payload) => ({
  type: ACTIONS.ON_RECEIVE_TEAM_LIST,
  payload
});
