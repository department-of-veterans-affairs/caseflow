import _ from 'lodash';

export const associateTasksWithAppeals = (serverData) => {
  const {
    appeals: { data: appeals },
    tasks: { data: tasks }
  } = serverData;

  // todo: Attorneys currently only have one task per appeal, but future users might have multiple
  _.each(tasks, (task) => {
    task.appeal = appeals.filter((appeal) => appeal.attributes.vacols_id === task.attributes.appeal_id)[0];
  });

  return {
    appeals,
    tasks
  };
};
