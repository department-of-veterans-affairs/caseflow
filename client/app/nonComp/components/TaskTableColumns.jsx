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

const createFilterDropdown = (values) => {
  return values.map((value) => {
    return {
      value,
      displayText: value
    };
  });
};

export const decisionReviewTypeColumn = (totalData) => {
  return {
    header: 'Type',
    align: 'left',
    enableFilter: true,
    tableData: totalData,
    columnName: 'type',
    valueFunction: (task) => task.type,
    label: 'Filter by type',
    valueName: 'type',
    getFilterValues: createFilterDropdown(['Clear category filter', 'Board Grant',
      'Higher-Level Review', 'Remand - Supplemental Claim', 'Record Request',
      'Supplemental Claim']),
    anyFiltersAreSet: false,
    // isDropdownFilterOpen: isFilterOpen,
    // toggleDropdownFilterVisibility: onFilterToggle,
    // setSelectedValue: onFilter,
    useCheckbox: true,
    // checkSelectedValue,
    // order determines where this column displays
    // make it -1 so this column is always last
    order: -1
  };
};
