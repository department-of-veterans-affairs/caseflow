import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import WorksheetFooter from './WorksheetFooter';
import WorksheetHeader from './WorksheetHeader';

export class HearingWorksheetPrinted extends React.Component {
  render() {
    return (
      <div>
        <WorksheetHeader print={true} />
        <WorksheetFooter
          veteranName={this.props.worksheet.veteran_fi_last_formatted}
        />
      </div>
    );
  }
}

HearingWorksheetPrinted.propTypes = {
  worksheet: PropTypes.object,
  worksheetAppeals: PropTypes.object,
  worksheetIssues: PropTypes.object
};

const mapStateToProps = (state) => ({
  worksheet: state.hearingWorksheet.worksheet,
  worksheetAppeals: state.hearingWorksheet.worksheetAppeals,
  worksheetIssues: state.hearingWorksheet.worksheetIssues
});

export default connect(mapStateToProps)(HearingWorksheetPrinted);
