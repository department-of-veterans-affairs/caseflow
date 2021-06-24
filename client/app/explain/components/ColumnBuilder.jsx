import * as React from 'react';
import Link from '../../components/Link';
import { css } from 'glamor';

const className = (rowData) => {
  return `${rowData.category} ${rowData.category}_${rowData.event_type}`;
};

export const timestampColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    cellClass: column.class,
    valueFunction: (rowData) => {
      const date = new Date(rowData[column.name]);

      if (rowData.category === 'clock') {
        return date.toLocaleDateString('en-US');
      }

      return date.toLocaleString('en-US', { hour12: false });

    },
    backendCanSort: true,
    label: 'Sort by timestamp',
    getSortValue: (rowData) => rowData[column.name]
  };
};

export const contextColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    cellClass: column.class,
    valueFunction: (rowData) => rowData[column.name],
    backendCanSort: true,
    label: 'Sort by context',
    getSortValue: (rowData) => rowData[column.name]
  };
};

export const objectTypeColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    cellClass: column.class,
    valueFunction: (rowData) => {
      return <span className={className(rowData)}>
        {rowData[column.name]}
      </span>;
    },
    backendCanSort: true,
    columnName: 'category',
    enableFilter: true,
    anyFiltersAreSet: true,
    label: 'Sort by category',
    bodyClassName: 'closestRegionalOffice.location_hash.city',
    getSortValue: (rowData) => rowData[column.name]
  };
};

export const eventTypeColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    cellClass: column.class,
    valueFunction: (rowData) => {
      return <span className={className(rowData)}>
        {rowData[column.name]}
      </span>;
    },
    backendCanSort: true,
    columnName: 'event_type',
    enableFilter: true,
    anyFiltersAreSet: true,
    label: 'Sort by event type',
    getSortValue: (rowData) => rowData[column.name]
  };
};

export const objectIdColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    cellClass: column.class,
    valueFunction: (rowData) => rowData[column.name],
    backendCanSort: true,
    label: 'Sort by object id',
    getSortValue: (rowData) => rowData[column.name]
  };
};

export const commentColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    cellClass: column.class,
    valueFunction: (rowData) => {
      return <span className={className(rowData)}>
        {rowData[column.name]} ({rowData.object_id})
      </span>;
    },
    backendCanSort: true,
    label: 'Sort by comment',
    getSortValue: (rowData) => rowData[column.name]
  };
};

export const relevanttDataColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    cellClass: column.class,
    valueFunction: (rowData) => {
      if (rowData[column.name]) {
        let jsonString = JSON.stringify(rowData[column.name], null, ' ');

        jsonString = jsonString.replace('{\n', '').replace('\n}', '');

        return <pre>{jsonString}</pre>;
      }

      return '';

    }
  };
};

export const detailsColumn = (column, handleModalOpen) => {
  const linkStyling = css({
    cursor: 'pointer',
  });

  return {
    header: column.header,
    name: column.name,
    cellClass: column.class,
    valueFunction: (rowData) => {
      let count = 0;
      const onClick = () => handleModalOpen(rowData[column.name]);

      for (let prop in rowData[column.name]) {
        if (Object.hasOwnProperty.call(rowData[column.name], prop)) {
          count += 1;
        }
      }
      if (count > 0) {
        return <span {...linkStyling}>
          <Link onClick={onClick}>
            {count}
          </Link>
        </span>;
      }

      return count;

    }
  };
};

