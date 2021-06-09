import React from 'react';

import QueueTable from '../queue/QueueTable';
import EXPLAIN_CONFIG from '../../constants/EXPLAIN';
import {
  timestampColumn,
  contextColumn,
  objectTypeColumn,
  eventTypeColumn,
  objectIdColumn,
  commentColumn,
  relevanttDataColumn,
  detailsColumn
} from './components/ColumnBuilder'

class Explain extends React.PureComponent {
  filterValuesForColumn = (column) =>
    column && column.filterable && column.filter_options;

  createColumnObject = (column, narratives) => {
    const filterOptions = this.filterValuesForColumn(column);
    const functionForColumn = {
      [EXPLAIN_CONFIG.COLUMNS.TIMESTAMP.name]: timestampColumn(
        column
      ),
      [EXPLAIN_CONFIG.COLUMNS.CONTEXT.name]: contextColumn(
        column
      ),
      [EXPLAIN_CONFIG.COLUMNS.OBJECT_TYPE.name]: objectTypeColumn(
        column,
        filterOptions,
        narratives
      ),
      [EXPLAIN_CONFIG.COLUMNS.EVENT_TYPE.name]: eventTypeColumn(
        column,
        filterOptions,
        narratives
      ),
      [EXPLAIN_CONFIG.COLUMNS.OBJECT_ID.name]: objectIdColumn(
        column
      ),
      [EXPLAIN_CONFIG.COLUMNS.COMMENT.name]: commentColumn(
        column
      ),
      [EXPLAIN_CONFIG.COLUMNS.RELEVANT_DATA.name]: relevanttDataColumn(
        column
      ),
      [EXPLAIN_CONFIG.COLUMNS.DETAILS.name]: detailsColumn(
        column
      )
    };
    return functionForColumn[column.name];
  }

  columnsFromConfig = (columns, narratives) => {
    let builtColumns = [];
    for (const [columnName, columnKeys] of Object.entries(columns)) {
      builtColumns.push(this.createColumnObject(columnKeys, narratives));
    }
    return builtColumns;
  }

  render = () => {
    const eventData = this.props.eventData;
    return ( 
      <QueueTable 
        columns={this.columnsFromConfig(EXPLAIN_CONFIG.COLUMNS, eventData)}
        rowObjects={eventData}
        summary="test table" slowReRendersAreOk />
    );
  };
}

export default Explain;
