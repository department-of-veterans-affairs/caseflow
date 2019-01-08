import { FORM_TYPES } from '../../intake/constants';
import _ from 'lodash';

export const formatTasks = (serverTasks) => {
  return (serverTasks || []).map((task) => {
    return {
      ...task,
      assignedOn: task.assigned_on,
      completedOn: task.completed_at,
      veteranParticipantId: task.veteran_participant_id
    };
  });
};

export const longFormNameFromShort = (shortFormName) => {
  return _.find(FORM_TYPES, { shortName: shortFormName }).name;
};
