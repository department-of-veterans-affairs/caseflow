import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import DOMPurify from 'dompurify';
import WorksheetFooter from './WorksheetFooter';
import WorksheetHeader from './WorksheetHeader';

export class HearingWorksheetPrinted extends React.Component {

  render() {
    const { worksheet } = this.props;

    return (
      <div>
        <WorksheetFooter
          veteranName={this.props.worksheet.veteran_fi_last_formatted}
        />
        <WorksheetHeader print={true} />
        <form className="cf-hearings-worksheet-form" id="cf-hearings-worksheet-summary">
          <div className="cf-hearings-worksheet-data">
            <label>Hearing Summary</label>
            <div 
              dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(worksheet.summary).replace(/\r|\n/g, "") }}
            />
          </div>
        </form>
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
