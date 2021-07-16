import React from 'react';

export const claimantColumn = () => {
  return {
    header: 'Claimant',
    valueFunction: (task) => {
      return <a href={`/decision_reviews/${task.business_line}/tasks/${task.id}`}>{task.claimant.name}</a>;
    },
    getSortValue: (task) => task.claimant.name
  };
};

export const veteranParticipantIdColumn = () => {
  return {
    header: 'Veteran Participant Id',
    valueFunction: (task) => task.veteranParticipantId,
    getSortValue: (task) => task.veteranParticipantId
  };
};

export const decisionReviewTypeColumn = (tasks) => {
  return {
    header: 'Type',
    name: 'type',
    align: 'left',
    valueFunction: (task) => task.type,
    label: 'Filter by type',
    valueName: 'type',
    enableFilter: true,
    tableData: tasks,
    columnName: 'type',
    anyFiltersAreSet: true,
    order: -1
  };
};

export const caseDetialsColumn = () => {
  return {
    header: 'Case Details',
    valueFunction: (task) => `${task.claimant.name} (${task.veteranParticipantId})`,
    getSortValue: (task) => task.claimant.name
  }
};

export const tasksColumn = () => {
  return {
    header: 'Tasks',
    valueFunction: (task) => task.type,
    getSortValue: (task) => task.claimant.name
  }
};
