import React from 'react';

import QueueTable from '../queue/QueueTable';
import EXPLAIN_CONFIG from '../../constants/EXPLAIN';

class Explain extends React.PureComponent {
  createColumnObject = (column) => {
    return { header: column.header, name: column.name }
  }

  columnsFromConfig = (columns) => {
    let builtColumns = [];
    for (const [columnName, columnKeys] of Object.entries(columns)) {
      builtColumns.push(this.createColumnObject(columnKeys));
    }
    return builtColumns;
  }
 
  render = () => {
    return ( 
      <QueueTable 
        columns={this.columnsFromConfig(EXPLAIN_CONFIG.COLUMNS)}
        rowObjects={[]}
        summary="test table" slowReRendersAreOk />
    );
  };
}

export default Explain;
