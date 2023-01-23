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

export const veteranSsnColumn = () => {
  return {
    header: 'Veteran SSN',
    valueFunction: (task) => task.veteranSSN,
    getSortValue: (task) => task.veteranSSN
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
