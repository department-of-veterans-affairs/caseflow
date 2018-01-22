import _ from 'lodash';

export const associateTasksWithAppeals = (serverData) => {
  const {
    appeals: { data: appeals },
    tasks: { data: tasks }
  } = serverData;

  // todo: Attorneys currently only have one task per appeal, but future users might have multiple
  _.each(appeals, (appeal) => {
    appeal.tasks = tasks.filter((task) => task.attributes.appeal_id === appeal.attributes.vacols_id);
  });

  return {
    appeals,
    tasks
  };
};
