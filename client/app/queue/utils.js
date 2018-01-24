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

/*
* Sorting hierarchy:
*  1 AOD vets and CAVC remands
*  2 All other appeals (originals, remands, etc)
*
*  Sort by docket date (form 9 date) oldest to
*  newest within each group
*/
export const sortTasks = (tasks) => {
  const partitionedTasks = _.partition(tasks, (task) =>
    task.appeal.attributes.aod || task.appeal.attributes.type === 'Court Remand'
  );

  _.each(partitionedTasks, _.sortBy('attributes.docket_date'));
  _.each(partitionedTasks, _.reverse);

  return _.flatten(partitionedTasks);
};
