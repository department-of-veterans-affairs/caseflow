import React from 'react';
import useSelector from 'react-redux';
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
import Modal from '../components/Modal'
import COPY from '../../COPY';

class Explain extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      modal: false,
      details: {}
    };
  }

  handleModalClose = () => {
    this.setState({ modal: false });
  };

  handleModalOpen = (details) => {
    this.setState({ modal: true, details: details });
  };

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
        column,
        this.handleModalOpen
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
    const showModal = this.state.modal
    const eventData = this.props.eventData;
    return ( 
      <React.Fragment>
        <QueueTable 
          columns={this.columnsFromConfig(EXPLAIN_CONFIG.COLUMNS, eventData)}
          rowObjects={eventData}
          summary="test table" slowReRendersAreOk />
        {showModal && <React.Fragment>
          <Modal
            title="Details"
            buttons={[
              {
                classNames: ['usa-button', 'cf-btn-link'],
                name: COPY.MODAL_CANCEL_BUTTON,
                onClick: this.handleModalClose
              }
            ]}
            closeHandler={this.handleModalClose}
          >
            {JSON.stringify(this.state.details)}
          </Modal>
        </React.Fragment>}
      </React.Fragment>
    );
  };
}

export default Explain;
