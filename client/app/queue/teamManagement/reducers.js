import { ACTIONS } from './constants';
import { update } from '../../util/ReducerUtil';

export const initialState = {
  dvcTeams: [],
  judgeTeams: [],
  vsos: [],
  privateBars: [],
  vhaProgramOffices: [],
  vhaRegionalOffices: [],
  otherOrgs: []
};

const teamManagementReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.ON_RECEIVE_TEAM_LIST:
    return update(state, {
      dvcTeams: { $set: action.payload.dvc_teams },
      judgeTeams: { $set: action.payload.judge_teams },
      privateBars: { $set: action.payload.private_bars },
      vsos: { $set: action.payload.vsos },
      vhaProgramOffices: { $set: action.payload.vha_program_offices },
      vhaRegionalOffices: { $set: action.payload.vha_regional_offices },
      otherOrgs: { $set: action.payload.other_orgs }
    });
  case ACTIONS.ON_RECEIVE_NEW_DVC_TEAM:
    return update(state, {
      dvcTeams: { $set: state.dvcTeams.concat(action.payload.org) }
    });
  case ACTIONS.ON_RECEIVE_NEW_JUDGE_TEAM:
    return update(state, {
      judgeTeams: { $set: state.judgeTeams.concat(action.payload.org) }
    });
  case ACTIONS.ON_RECEIVE_NEW_PRIVATE_BAR:
    return update(state, {
      privateBars: { $set: state.privateBars.concat(action.payload.org) }
    });
  case ACTIONS.ON_RECEIVE_NEW_VSO:
    return update(state, {
      vsos: { $set: state.vsos.concat(action.payload.org) }
    });
  default:
    return state;
  }
};

export default teamManagementReducer;
