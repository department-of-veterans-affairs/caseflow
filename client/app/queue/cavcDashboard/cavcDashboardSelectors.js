import { find, findIndex } from 'lodash';
import { createSelector } from 'reselect';

const getAllCavcDashboards = (state) => state.cavcDashboard.cavc_dashboards;
const getCavcDashboardId = (state, props) => props.dashboardId;

export const getCavcDashboardById = createSelector(
  [getAllCavcDashboards, getCavcDashboardId],
  (cavcDashboards, cavcDashboardId) => find(cavcDashboards, (cavcDashboard) => cavcDashboard.id === cavcDashboardId)
);

export const getCavcDashboardIndex = createSelector(
  [getAllCavcDashboards, getCavcDashboardId],
  (cavcDashboards, cavcDashboardId) => findIndex(
    cavcDashboards, (cavcDashboard) => cavcDashboard.id === cavcDashboardId)
);
