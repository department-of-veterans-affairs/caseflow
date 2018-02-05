import React from 'react';
import _ from 'lodash';
import moment from 'moment';

export const associateTasksWithAppeals = (serverData = {}) => {
  const {
    appeals: { data: appeals },
    tasks: { data: tasks }
  } = serverData;

  // todo: Attorneys currently only have one task per appeal, but future users might have multiple
  _.each(tasks, (task) => {
    task.vacolsId = _(appeals).
      filter((appeal) => appeal.attributes.vacols_id === task.attributes.appeal_id).
      map('attributes.vacols_id').
      head();
  });

  const tasksById = _.keyBy(tasks, 'id');
  const appealsById = _.keyBy(appeals, 'attributes.vacols_id');

  return {
    appeals: appealsById,
    tasks: tasksById
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
export const sortTasks = ({ tasks = {}, appeals = {} }) => {
  const partitionedTasks = _.partition(tasks, (task) =>
    appeals[task.vacolsId].attributes.aod || appeals[task.vacolsId].attributes.type === 'Court Remand'
  );

  _.each(partitionedTasks, _.sortBy('attributes.docket_date'));
  _.each(partitionedTasks, _.reverse);

  return _.flatten(partitionedTasks);
};

export const dateString = (date, dateFormat = 'MM/DD/YY') => <span>
  {moment(date).format(dateFormat)}
</span>;
