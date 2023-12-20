import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';

import ApiUtil from 'app/util/ApiUtil';
import StringUtil from 'app/util/StringUtil';

export const fetchTeamManagement = createAsyncThunk(
  'teamManagement/fetchTeamManagement',
  async () => {
    try {
      const res = await ApiUtil.get('/team_management');

      return res?.body;
    } catch (error) {
      console.error('Error fetching teamManagement data', error);
      throw error;
    }
  }
);

export const updateOrg = createAsyncThunk(
  'teamManagement/updateOrg',
  async ({ orgId, updates }) => {
    try {
      const payload = {
        data: { organization: { ...updates } }
      };
      const res = await ApiUtil.patch(`/team_management/${orgId}`, payload);

      return res?.body?.org;
    } catch (error) {
      console.error('Error updating organization', error);
      throw error;
    }
  }
);

const initialState = {
  data: {
    dvcTeams: [],
    judgeTeams: [],
    vsos: [],
    privateBars: [],
    vhaProgramOffices: [],
    vhaRegionalOffices: [],
    otherOrgs: []
  },
  loading: false,
  statuses: {},
};

const resetState = () => ({ ...initialState });

const teamManagementSlice = createSlice({
  name: 'teamManagement',
  initialState,
  reducers: {
    reset: resetState,
    clearStatus: (state, action) => {
      state.statuses[action.payload.orgId] = {
        saved: false,
        loading: false,
        error: false
      };
    },
    orgAdded: (state, action) => {
      const { type, org } = action.payload;

      state.data[type] = [...state.data[type], org];
    },
    dvcTeamAdded: (state, action) => {
      state.data.dvcTeams = [...state.data.dvcTeams, action.payload];
    },
    judgeTeamAdded: (state, action) => {
      state.data.judgeTeams = [...state.data.judgeTeams, action.payload];
    },
    vsoAdded: (state, action) => {
      state.data.vsos = [...state.data.vsos, action.payload];
    },
    privateBarAdded: (state, action) => {
      state.data.privateBars = [...state.data.privateBars, action.payload];
    },
    vhaProgramOfficeAdded: (state, action) => {
      state.data.vhaProgramOffices = [...state.data.vhaProgramOffices, action.payload];
    },
    vhaRegionalOfficeAdded: (state, action) => {
      state.data.vhaRegionalOffices = [...state.data.vhaRegionalOffices, action.payload];
    },
    otherOrgAdded: (state, action) => {
      state.data.otherOrgs = [...state.data.otherOrgs, action.payload];
    },
  },
  extraReducers: {
    [fetchTeamManagement.pending]: (state) => {
      state.loading = true;
    },
    [fetchTeamManagement.fulfilled]: (state, { payload }) => {
      const newVals = {};

      // Need to convert the object keys to camelCase
      Object.entries(payload).forEach(([key, val]) => {
        newVals[StringUtil.snakeCaseToCamelCase(key)] = val;
      });

      state.data = { ...newVals };
      state.loading = false;
    },
    [fetchTeamManagement.rejected]: (state) => {
      state.loading = false;
    },
    [updateOrg.pending]: (state, action) => {
      const { orgId } = action.meta.arg;

      state.statuses[orgId] = {
        saved: false,
        loading: true,
        error: false
      };
    },
    [updateOrg.fulfilled]: (state, action) => {
      const { orgId } = action.meta.arg;

      state.statuses[orgId] = {
        saved: true,
        loading: false,
        error: false
      };
    },
    [updateOrg.rejected]: (state, action) => {
      const { orgId } = action.meta.arg;

      state.statuses[orgId] = {
        saved: false,
        loading: false,
        error: true
      };
    },
  },
});

export const {
  reset,
  clearStatus,
  orgAdded,
  dvcTeamAdded,
  judgeTeamAdded,
  vsoAdded,
  privateBarAdded,
  vhaProgramOfficeAdded,
  vhaRegionalOfficeAdded,
  otherOrgAdded,
} = teamManagementSlice.actions;

export default teamManagementSlice.reducer;
