import * as React from 'react';
import COPY from '../../../COPY';
import EXPLAIN_CONFIG from '../../../constants/EXPLAIN';

export const timestampColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    valueFunction: (rowData) => {
      const date = new Date(rowData.[column.name])
      if (rowData.['category'] == 'clock') {
        return date.toLocaleDateString('en-US')
      } else {
        return date.toLocaleString('en-US')
      }
    },
    backendCanSort: true,
    label: 'Sort by timestamp',
    getSortValue: (rowData) => rowData.[column.name]
  }
}

export const contextColumn = (column) => {
  return {
    // header: column.header,
    // name: column.name,
    // valueFunction: (rowData) => rowData.[column.name],
    // backendCanSort: true,
    // label: 'Sort by context',
    // getSortValue: (rowData) => rowData.[column.name]
  }
}

export const objectTyleColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    valueFunction: (rowData) => rowData.[column.name],
    backendCanSort: true,
    label: 'Sort by category',
    getSortValue: (rowData) => rowData.[column.name]
  }
}

export const eventTypeColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    valueFunction: (rowData) => rowData.[column.name],
    backendCanSort: true,
    label: 'Sort by event type',
    getSortValue: (rowData) => rowData.[column.name]
  }
}

export const objectIdColumn = (column) => {
  return {
    // header: column.header,
    // name: column.name,
    // valueFunction: (rowData) => rowData.[column.name],
    // backendCanSort: true,
    // label: 'Sort by object id',
    // getSortValue: (rowData) => rowData.[column.name]
  }
}

export const commentColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    valueFunction: (rowData) => {
      return `${rowData.[column.name]} (${rowData.['object_id']})`
    },
    backendCanSort: true,
    label: 'Sort by comment',
    getSortValue: (rowData) => rowData.[column.name]
  }
}

export const relevanttDataColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    valueFunction: (rowData) => {
      if (rowData.[column.name]) {
        return JSON.stringify(rowData.[column.name])
      } else {
        return '';
      }
    }
  }
}

export const detailsColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    valueFunction: (rowData) => JSON.stringify(rowData.[column.name])
  }
}

