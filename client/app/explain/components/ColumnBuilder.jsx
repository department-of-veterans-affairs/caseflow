import * as React from 'react';
import COPY from '../../../COPY';
import EXPLAIN_CONFIG from '../../../constants/EXPLAIN';
import Modal from '../../components/Modal'
import Link from '../../components/Link'
import { css } from 'glamor';

export const timestampColumn = (column) => {
  return {
    header: column.header,
    name: column.name,
    cellClass: (rowData) => column.class,
    valueFunction: (rowData) => {
      const date = new Date(rowData.[column.name])
      if (rowData.['category'] == 'clock') {
        return date.toLocaleDateString('en-US');
      } else {
        return date.toLocaleString('en-US', { hour12: false });
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
    // cellClass: column.class,
    // valueFunction: (rowData) => rowData.[column.name],
    // backendCanSort: true,
    // label: 'Sort by context',
    // getSortValue: (rowData) => rowData.[column.name]
  }
}

export const objectTypeColumn = (column, filterOptions) => {
  return {
    header: column.header,
    name: column.name,
    cellClass: column.class,
    valueFunction: (rowData) => rowData.[column.name],
    backendCanSort: true,
    columnName: 'category',
    enableFilter: true,
    anyFiltersAreSet: true,
    label: 'Sort by category',
    bodyClassName: 'closestRegionalOffice.location_hash.city',
    getSortValue: (rowData) => rowData.[column.name]
  }
}

export const eventTypeColumn = (column, filterOptions) => {
  return {
    header: column.header,
    name: column.name,
    cellClass: column.class,
    valueFunction: (rowData) => rowData.[column.name],
    backendCanSort: true,
    columnName: 'event_type',
    enableFilter: true,
    anyFiltersAreSet: true,
    label: 'Sort by event type',
    getSortValue: (rowData) => rowData.[column.name]
  }
}

export const objectIdColumn = (column) => {
  return {
    // header: column.header,
    // name: column.name,
    // cellClass: column.class,
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
    cellClass: column.class,
    valueFunction: (rowData) => {
      return `${rowData.[column.name]} (${rowData.['object_id']})`;
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
    cellClass: column.class,
    valueFunction: (rowData) => {
      if (rowData.[column.name]) {
        return JSON.stringify(rowData.[column.name]);
      } else {
        return '';
      }
    }
  }
}

export const detailsColumn = (column, handleModalOpen) => {
  const linkStyling = css({
    cursor: 'pointer',
  });

  let displayDetails = (details) => {
    <Modal
      title="Details"
      buttons={[
        {
          classNames: ['usa-button', 'cf-btn-link'],
          name: COPY.MODAL_CANCEL_BUTTON,
        }
      ]}
    >
      JSON.stringify(details)
    </Modal>
  }

  return {
    header: column.header,
    name: column.name,
    cellClass: column.class,
    valueFunction: (rowData) => {
      var count = 0;
      const onClick = () => handleModalOpen(rowData.[column.name]);

      for(var prop in rowData.[column.name]) {
        if(rowData.[column.name].hasOwnProperty(prop))
          ++count;
      }
      if (count > 0) {
        return <span {...linkStyling}> 
          <Link onClick={onClick}>
            {count}
          </Link>
        </span>;
      } else {
        return count;
      }

    }
  }
}

