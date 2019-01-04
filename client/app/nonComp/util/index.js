export const formatTasks = (severTasks) => {
  return severTasks.map((task) => {
    return {
      ...task,
      assignedOn: task.assigned_on,
      veteranParticipantId: task.veteran_participant_id
    };
  });
};
