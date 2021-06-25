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
  };
};

export const contextColumn = (column, filterOptions, narratives) => {
  return {
    header: column.header,
    name: column.name,
    cellClass: column.class,
    valueFunction: (rowData) => rowData[column.name],
    filterOptions,
    tableData: narratives,
  };
};

// a.k.a. Category column
export const objectTypeColumn = (column, filterOptions, narratives) => {
  return {
    header: column.header,
    name: column.name,
    cellClass: column.class,
    valueFunction: (rowData) => {
      return <span className={className(rowData)}>
        {rowData[column.name]}
      </span>;
    },
    filterOptions,
    tableData: narratives,
    columnName: 'category',
    enableFilter: true,
    label: 'Filter by category',
    anyFiltersAreSet: true,
  };
};

// a.k.a. Type column
export const eventTypeColumn = (column, filterOptions, narratives) => {
  return {
    header: column.header,
    name: column.name,
    cellClass: column.class,
    valueFunction: (rowData) => {
      return <span className={className(rowData)}>
        {rowData[column.name]}
      </span>;
    },
    filterOptions,
    tableData: narratives,
    columnName: 'event_type',
    enableFilter: true,
    label: 'Filter by event type',
    anyFiltersAreSet: true,
  };
};

export const objectIdColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    cellClass: column.class,
    valueFunction: (rowData) => rowData[column.name],
  };
};

// a.k.a. Narrative column
export const commentColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    cellClass: column.class,
    valueFunction: (rowData) => {
      return <span className={className(rowData)}>
        {rowData[column.name] && <div>{rowData[column.name]}<br /></div>}
        ({rowData.object_id})
      </span>;
    },
  };
};

const formatJson = (obj) => {
  return JSON.stringify(obj, null, ' ').
    replace('{\n', '').
    replace('\n}', '');
};

export const relevantDataColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    cellClass: column.class,
    valueFunction: (rowData) => {
      return rowData[column.name] ? formatJson(rowData[column.name]) : '';
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

      for (let prop in rowData[column.name]) {
        if (Object.hasOwnProperty.call(rowData[column.name], prop)) {
          count += 1;
        }
      }
      if (count > 0) {
        const onClick = () => handleModalOpen(rowData[column.name]);
        const expandableDetail = <details className="jsonDetails"><summary>(details)</summary>
          <pre>{ formatJson(rowData[column.name]) }</pre>
        </details>;

        return <span {...linkStyling}>
          <Link onClick={onClick}>
            {count}
          </Link>
          {expandableDetail}
        </span>;
      }
    }
  };
};
