import * as React from 'react';
import ReactDOM from 'react-dom';
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

const linkToDetailsPane = (formattedData, handleModalOpen, data, count) => {
  const showInPane = function () {
    const sidePanel = window.document.getElementById('side_panel');
    const detailsPane = window.document.getElementById('details_pane_section');

    if (!detailsPane || !sidePanel || detailsPane.style.display === 'none' || sidePanel.style.display === 'none') {
      // Update React state with new data
      handleModalOpen(data);
    } else {
      // Add React component to non-React parent element.
      // Ensure that the React component is not moved or removed from its parent element outside of React.
      // Otherwise warnings are emitted in the browser console.
      const detailsContentPane = window.document.getElementById('details_content_for_react');

      ReactDOM.render(formattedData, detailsContentPane);
    }
  };

  return <div id="detailPaneLink"><Link onClick={showInPane}>{count} attributes</Link></div>;
};

const inlineDetail = (formattedData) => <div>
  <details className="jsonDetails">
    <summary>details</summary>
    { formattedData }
  </details>
</div>;

const linkStyling = css({
  cursor: 'pointer',
});

export const detailsColumn = (column, handleModalOpen) => {
  return {
    header: column.header,
    name: column.name,
    cellClass: column.class,
    valueFunction: (rowData) => {
      const eventProperties = rowData[column.name];
      const count = eventProperties ? Object.keys(eventProperties).length : 0;

      if (count > 0) {
        const formattedData = <pre id={`formattedEventData_${rowData.object_id}`} className="event_detail">
          { formatJson(eventProperties) }
        </pre>;

        return <span {...linkStyling}>
          {linkToDetailsPane(formattedData, handleModalOpen, eventProperties, count)}
          {inlineDetail(formattedData)}
        </span>;
      }
    }
  };
};
