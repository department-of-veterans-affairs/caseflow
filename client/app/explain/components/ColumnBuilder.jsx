import * as React from 'react';
import COPY from '../../../COPY';
import EXPLAIN_CONFIG from '../../../constants/EXPLAIN';

export const timestampColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    valueFunction: (rowData) => rowData.[column.name],
    backendCanSort: true,
    label: 'Sort by timestamp',
getSortValue: (rowData) => rowData.[column.name]
  }
}

export const contextColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    valueFunction: (rowData) => rowData.[column.name],
    backendCanSort: true,
    label: 'Sort by context',
    getSortValue: (rowData) => rowData.[column.name]
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
    header: column.header,
    name: column.name,
    valueFunction: (rowData) => rowData.[column.name],
    backendCanSort: true,
    label: 'Sort by object id',
    getSortValue: (rowData) => rowData.[column.name]
  }
}

export const commentColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    valueFunction: (rowData) => rowData.[column.name],
    backendCanSort: true,
    label: 'Sort by comment',
    getSortValue: (rowData) => rowData.[column.name]
  }
}

export const relevanttDataColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    valueFunction: (rowData) => JSON.stringify(rowData.[column.name])
  }
}

export const detailsColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    valueFunction: (rowData) => JSON.stringify(rowData.[column.name])
  }
}

