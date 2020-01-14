import React from 'react';
import PropTypes from 'prop-types';
import QueueTable from '../../../queue/QueueTable';
import { tableNumberStyling } from './styles';

class AssignHearingsTable extends React.Component {

  render () {
    let { columns, rowObjects } = this.props;

    return (
      <QueueTable
        columns={columns}
        rowObjects={rowObjects}
        summary="scheduled-hearings-table"
        slowReRendersAreOk
        bodyStyling={tableNumberStyling}
      />
    );
  }
}

AssignHearingsTable.propTypes = {
  user: PropTypes.object,
  columns: PropTypes.array,
  rowObjects: PropTypes.array
};

export default AssignHearingsTable;
