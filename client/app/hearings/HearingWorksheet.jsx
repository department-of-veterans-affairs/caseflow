import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Textarea from 'react-textarea-autosize';
import HearingWorksheetStream from './components/HearingWorksheetStream';
import PrintPageBreak from '../components/PrintPageBreak';
import WorksheetHeader from './components/WorksheetHeader';
import classNames from 'classnames';
import AutoSave from '../components/AutoSave';
import { LOGO_COLORS } from '../constants/AppConstants';
import _ from 'lodash';
import { getReaderLink } from './util/index';
import WorksheetHeaderVeteranSelection from './components/WorksheetHeaderVeteranSelection';

// TODO Move all stream related to streams container
import HearingWorksheetDocs from './components/HearingWorksheetDocs';

import {
  onContentionsChange,
  onMilitaryServiceChange,
  onEvidenceChange,
  onCommentsForAttorneyChange,
  toggleWorksheetSaving,
  setWorksheetSaveFailedStatus,
  saveWorksheet,
  saveDocket
} from './actions/Dockets';

import { saveIssues } from './actions/Issue';

class WorksheetFormEntry extends React.PureComponent {
  render() {
    const textAreaProps = {
      minRows: 3,
      maxRows: 5000,
      value: this.props.value || '',
      ..._.pick(
        this.props,
        [
          'name',
          'onChange',
          'id',
          'minRows'
        ]
      )
    };

    return <div className="cf-hearings-worksheet-data">
      <label htmlFor={this.props.id}>{this.props.name}</label>
      {this.props.print ?
        <p>{this.props.value}</p> :
        <Textarea {...textAreaProps} />}
    </div>;
  }
}
export class HearingWorksheet extends React.PureComponent {

  componentDidUpdate(prevProps) {
    if (prevProps.worksheet !== this.props.worksheet) {
      document.title = `${this.props.worksheet.veteran_fi_last_formatted}'s ${document.title}`;
    }
  }

  save = (worksheet, worksheetIssues) => () => {
    this.props.saveWorksheet(worksheet);
    this.props.saveIssues(worksheetIssues);
  };

  openPdf = (worksheet, worksheetIssues) => () => {
    Promise.resolve([this.save(worksheet, worksheetIssues)()]).then(() => {
      window.open(`${window.location.pathname}/print`, '_blank');
    });
  };

  onContentionsChange = (event) => this.props.onContentionsChange(event.target.value);
  onMilitaryServiceChange = (event) => this.props.onMilitaryServiceChange(event.target.value);
  onEvidenceChange = (event) => this.props.onEvidenceChange(event.target.value);
  onCommentsForAttorneyChange = (event) => this.props.onCommentsForAttorneyChange(event.target.value);

  render() {
    let { worksheet, worksheetIssues } = this.props;
    let readerLink = getReaderLink(worksheet);
    const appellant = worksheet.appellant_mi_formatted ?
      worksheet.appellant_mi_formatted : worksheet.veteran_mi_formatted;

    const worksheetHeader = <WorksheetHeader
      print={this.props.print}
      veteranLawJudge={this.props.veteran_law_judge}
      appellant={appellant}
    />;

    const firstWorksheetPage = <div>
      {worksheetHeader}
      <HearingWorksheetDocs {...this.props} />
      <HearingWorksheetStream {...this.props} print={this.props.print} />
    </div>;

    const secondWorksheetPage = <div className="cf-hearings-second-page">
      {this.props.print && worksheetHeader}

      <form className="cf-hearings-worksheet-form">
        <WorksheetFormEntry
          name="Periods and circumstances of service"
          value={worksheet.military_service}
          onChange={this.onMilitaryServiceChange}
          id="worksheet-military-service"
          minRows={1}
          print={this.props.print}
        />
        <WorksheetFormEntry
          name="Contentions"
          value={worksheet.contentions}
          onChange={this.onContentionsChange}
          id="worksheet-contentions"
          print={this.props.print}
        />
        <WorksheetFormEntry
          name="Evidence"
          value={worksheet.evidence}
          onChange={this.onEvidenceChange}
          id="worksheet-evidence"
          print={this.props.print}
        />
        <WorksheetFormEntry
          name="Comments and special instructions to attorneys"
          value={worksheet.comments_for_attorney}
          id="worksheet-comments-for-attorney"
          onChange={this.onCommentsForAttorneyChange}
          print={this.props.print}
        />
      </form>
    </div>;

    const wrapperClassNames = classNames('cf-hearings-worksheet', {
      'cf-app-segment--alt': !this.props.print
    });

    return <div>
      {!this.props.print &&
        <div>
          <AutoSave
            save={this.save(worksheet, worksheetIssues)}
            spinnerColor={LOGO_COLORS.HEARINGS.ACCENT}
            isSaving={this.props.worksheetIsSaving}
            saveFailed={this.props.saveWorksheetFailed}
          />
          <WorksheetHeaderVeteranSelection openPdf={this.openPdf}
            history={this.props.history} />
        </div>
      }
      <div className={wrapperClassNames}>
        {firstWorksheetPage}
        <PrintPageBreak />
        {secondWorksheetPage}
      </div>
      {!this.props.print &&
      <div className="cf-push-right">
        <Link
          onClick={this.openPdf(worksheet, worksheetIssues)}
          button="secondary">
          Save as PDF
        </Link>
        <Link
          name="review-efolder"
          href={`${readerLink}?category=case_summary`}
          button="primary"
          target="_blank">
            Review Claims Folder</Link>
      </div>
      }
    </div>;
  }
}

const mapStateToProps = (state) => ({
  worksheet: state.worksheet,
  worksheetAppeals: state.worksheetAppeals,
  worksheetIssues: state.worksheetIssues,
  saveWorksheetFailed: state.saveWorksheetFailed
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onContentionsChange,
  onMilitaryServiceChange,
  onEvidenceChange,
  onCommentsForAttorneyChange,
  toggleWorksheetSaving,
  saveWorksheet,
  setWorksheetSaveFailedStatus,
  saveIssues,
  saveDocket
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheet);
