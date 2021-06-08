import React from 'react';

import QueueTable from '../queue/QueueTable';
import EXPLAIN_CONFIG from '../../constants/EXPLAIN';

class Explain extends React.PureComponent {
  createColumnObject = (column, data) => {
    console.log(data)
    return { header: column.header, 
             name: column.name,
             valueFunction: (task) => task.[column.name] }
  }

  columnsFromConfig = (columns, data) => {
    console.log(data)
    let builtColumns = [];
    for (const [columnName, columnKeys] of Object.entries(columns)) {
      builtColumns.push(this.createColumnObject(columnKeys, data));
    }
    return builtColumns;
  }
 
  render = () => {
    const eventData = this.props.eventData;
    console.log(eventData)
    return ( 
      <QueueTable 
        columns={this.columnsFromConfig(EXPLAIN_CONFIG.COLUMNS, eventData)}
        rowObjects={eventData}
        summary="test table" slowReRendersAreOk />
    );
  };
}

export default Explain;
