import React from 'react';

import QueueTable from '../queue/QueueTable';
import EXPLAIN_CONFIG from '../../constants/EXPLAIN';

// import queueReducer, { initialState } from './reducers';

// import QueueApp from './QueueApp';
// import ReduxBase from '../components/ReduxBase';

// const Explain = (props) => {
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
    const data = [];
    console.log(this.columnsFromConfig(EXPLAIN_CONFIG.COLUMNS));
    return ( 
      <QueueTable 
        columns={this.columnsFromConfig(EXPLAIN_CONFIG.COLUMNS)}
        rowObjects={data}
        summary="test table" slowReRendersAreOk />
    );
  };
}

export default Explain;
