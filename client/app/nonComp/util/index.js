export const formatTasks = (serverTasks) => {
  return (serverTasks || []).map((task) => {
    return {
      ...task,
      assignedOn: task.assigned_on,
      veteranParticipantId: task.veteran_participant_id
    };
  });
};
