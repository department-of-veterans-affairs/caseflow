import { find } from 'lodash';
import { createSelector } from 'reselect';

const getAllCavcRemands = (state) => state.cavcDashboard.cavc_remands;
const getCavcRemandId = (state, props) => props.remandId;

export const getCavcRemandById = createSelector(
  [getAllCavcRemands, getCavcRemandId],
  (cavcRemands, cavcRemandId) => find(cavcRemands, (cavcRemand) => cavcRemand.id === cavcRemandId)
);
