import React from 'react';

import QueueTable from '../queue/QueueTable';
import EXPLAIN_CONFIG from '../../constants/EXPLAIN';
import {
  timestampColumn,
  contextColumn,
  objectTyleColumn,
  eventTypeColumn,
  objectIdColumn,
  commentColumn,
  relevanttDataColumn,
  detailsColumn
} from './components/ColumnBuilder'

class Explain extends React.PureComponent {
  createColumnObject = (column) => {
    const functionForColumn = {
      [EXPLAIN_CONFIG.COLUMNS.TIMESTAMP.name]: timestampColumn(
        column
      ),
      [EXPLAIN_CONFIG.COLUMNS.CONTEXT.name]: contextColumn(
        column
      ),
      [EXPLAIN_CONFIG.COLUMNS.OBJECT_TYPE.name]: objectTyleColumn(
        column
      ),
      [EXPLAIN_CONFIG.COLUMNS.EVENT_TYPE.name]: eventTypeColumn(
        column
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
    console.log(column)
    return functionForColumn[column.name];

    // return { header: column.header, 
    //          name: column.name,
    //          valueFunction: (task) => task.[column.name] }
  }

  columnsFromConfig = (columns) => {
    let builtColumns = [];
    for (const [columnName, columnKeys] of Object.entries(columns)) {
      builtColumns.push(this.createColumnObject(columnKeys));
    }
    return builtColumns;
  }
 
  render = () => {
    const eventData = this.props.eventData;
    console.log(eventData)
    return ( 
      <QueueTable 
        columns={this.columnsFromConfig(EXPLAIN_CONFIG.COLUMNS)}
        rowObjects={eventData}
        summary="test table" slowReRendersAreOk />
    );
  };
}

export default Explain;
