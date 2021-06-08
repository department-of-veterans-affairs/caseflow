import * as React from 'react';
import COPY from '../../../COPY';
import EXPLAIN_CONFIG from '../../../constants/EXPLAIN';

export const timestampColumn = (column) => {
	console.log(column)
	return {
		header: column.header,
		name: column.name,
		valueFunction: (rowData) => rowData.[column.name]
	}
}

export const contextColumn = (column) => {
	return {
		header: column.header,
		name: column.name,
		valueFunction: (rowData) => rowData.[column.name]
	}
}

export const objectTyleColumn = (column) => {
	return {
		header: column.header,
		name: column.name,
		valueFunction: (rowData) => rowData.[column.name]
	}
}

export const eventTypeColumn = (column) => {
	return {
		header: column.header,
		name: column.name,
		valueFunction: (rowData) => rowData.[column.name]
	}
}

export const objectIdColumn = (column) => {
	return {
		header: column.header,
		name: column.name,
		valueFunction: (rowData) => rowData.[column.name]
	}
}

export const commentColumn = (column) => {
	return {
		header: column.header,
		name: column.name,
		valueFunction: (rowData) => rowData.[column.name]
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

