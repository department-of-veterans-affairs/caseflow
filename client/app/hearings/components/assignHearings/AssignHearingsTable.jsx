import React from 'react';
import { css } from 'glamor';
import QueueTable from '../../../queue/QueueTable';
import PropTypes from 'prop-types';

const tableNumberStyling = css({
  '& tr > td:first-child': {
    paddingRight: 0
  },
  '& td:nth-child(2)': {
    paddingLeft: 0
  }
});

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
