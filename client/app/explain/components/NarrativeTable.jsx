import React from 'react';
import QueueTable from '../../queue/QueueTable';
import EXPLAIN_CONFIG from '../../../constants/EXPLAIN';
import {
  timestampColumn,
  objectTypeColumn,
  eventTypeColumn,
  commentColumn,
  relevantDataColumn,
  detailsColumn
} from './ColumnBuilder';
import Modal from '../../components/Modal';
import COPY from '../../../COPY';
import { css } from 'glamor';
import PropTypes from 'prop-types';

class NarrativeTable extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      modal: false,
      details: {},
      narratives: this.props.eventData
    };
  }

  handleModalClose = () => {
    this.setState({ modal: false });
  };

  handleModalOpen = (details) => {
    this.setState({ modal: true, details });
  };

  filterValuesForColumn = (column) =>
    column && column.filterable && column.filter_options;

  createColumnObject = (column) => {
    const filterOptions = this.filterValuesForColumn(column);
    const functionForColumn = {
      [EXPLAIN_CONFIG.COLUMNS.TIMESTAMP.name]: timestampColumn(
        column
      ),
      [EXPLAIN_CONFIG.COLUMNS.OBJECT_TYPE.name]: objectTypeColumn(
        column,
        filterOptions,
        this.state.narratives
      ),
      [EXPLAIN_CONFIG.COLUMNS.EVENT_TYPE.name]: eventTypeColumn(
        column,
        filterOptions,
        this.state.narratives
      ),
      [EXPLAIN_CONFIG.COLUMNS.COMMENT.name]: commentColumn(
        column
      ),
      [EXPLAIN_CONFIG.COLUMNS.RELEVANT_DATA.name]: relevantDataColumn(
        column
      ),
      [EXPLAIN_CONFIG.COLUMNS.DETAILS.name]: detailsColumn(
        column,
        this.handleModalOpen
      )
    };

    return functionForColumn[column.name];
  }

  columnsFromConfig = (columns) => {
    let builtColumns = [];

    for (const column of Object.values(columns)) {
      builtColumns.push(this.createColumnObject(column));
    }

    return builtColumns;
  }

  detailsModalContent = (details) => {
    let jsonString = JSON.stringify(details, null, ' ');

    return jsonString.replace('{\n', '').replace('\n}', '');
  }

  render = () => {
    const showModal = this.state.modal;
    const textAreaStyling = css({
      wideth: '100%',
      fontSize: '10pt'
    });

    return (
      <React.Fragment>
        <QueueTable
          id="events_table"
          columns={this.columnsFromConfig(EXPLAIN_CONFIG.COLUMNS, this.state.narratives)}
          rowClassNames={(event) => event.category}
          rowObjects={this.state.narratives}
          summary="Appeal events table" slowReRendersAreOk />
        {showModal && <React.Fragment>
          <Modal
            title="Details"
            buttons={[
              {
                classNames: ['usa-button', 'cf-btn-link'],
                name: COPY.MODAL_CLOSE_BUTTON,
                onClick: this.handleModalClose
              }
            ]}
            closeHandler={this.handleModalClose}
          >
            <textarea readOnly {...textAreaStyling} value={this.detailsModalContent(this.state.details)} />
          </Modal>
        </React.Fragment>}
      </React.Fragment>
    );
  };
}

NarrativeTable.propTypes = {
  eventData: PropTypes.array,
};

export default NarrativeTable;
