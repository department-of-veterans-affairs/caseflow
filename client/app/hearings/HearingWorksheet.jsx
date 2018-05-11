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
import WorksheetHeaderVeteranSelection from './components/WorksheetHeaderVeteranSelection';
import { now } from './util/DateUtil';
import { CATEGORIES, ACTIONS } from './analytics';
import WorksheetFooter from './components/WorksheetFooter';
import LoadingScreen from '../components/LoadingScreen';

// TODO Move all stream related to streams container
import HearingWorksheetDocs from './components/HearingWorksheetDocs';

import {
  onContentionsChange,
  onEvidenceChange,
  onCommentsForAttorneyChange,
  toggleWorksheetSaving,
  setWorksheetTimeSaved,
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

  componentDidMount() {
    document.title = this.getWorksheetTitle();
  }

  componentDidUpdate(prevProps) {
    if (prevProps.worksheet !== this.props.worksheet) {
      document.title = this.getWorksheetTitle();
    }
  }

  getWorksheetTitle = () => `${this.props.worksheet.veteran_fi_last_formatted}'s ${document.title}`;

  save = (worksheet, worksheetIssues) => () => {
    this.props.saveWorksheet(worksheet);
    this.props.saveIssues(worksheetIssues);
  };

  openPdf = (worksheet, worksheetIssues) => () => {
    window.analyticsEvent(CATEGORIES.HEARING_WORKSHEET_PAGE, ACTIONS.CLICK_ON_SAVE_TO_PDF);
    Promise.resolve([this.save(worksheet, worksheetIssues)()]).then(() => {
      window.open(`${window.location.pathname}/print`, '_blank', 'noopener noreferrer');
    });
  };

  onContentionsChange = (event) => this.props.onContentionsChange(event.target.value);
  onEvidenceChange = (event) => this.props.onEvidenceChange(event.target.value);
  onCommentsForAttorneyChange = (event) => this.props.onCommentsForAttorneyChange(event.target.value);

  render() {
    let { worksheet, worksheetIssues, fetchingWorksheet } = this.props;
    const appellant = worksheet.appellant_mi_formatted ?
      worksheet.appellant_mi_formatted : worksheet.veteran_mi_formatted;

    const worksheetHeader = <WorksheetHeader
      print={this.props.print}
      appellant={appellant}
    />;

    const firstWorksheetPage = <div>
      {worksheetHeader}
      <HearingWorksheetDocs {...this.props} />
      <HearingWorksheetStream {...this.props} print={this.props.print} />
      {this.props.print &&
        <WorksheetFooter
          veteranName={this.props.worksheet.veteran_fi_last_formatted}
        />
      }
    </div>;


    const secondWorksheetPage = <div>

      <form className="cf-hearings-worksheet-form">
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
      {this.props.print &&
        <WorksheetFooter
          veteranName={this.props.worksheet.veteran_fi_last_formatted}
        />
      }
    </div>;

    const wrapperClassNames = classNames('cf-hearings-worksheet', {
      'cf-app-segment--alt': !this.props.print
    });

    const printWrapperClassNames = classNames('cf-hearings-worksheet', {
      'cf-app-segment--alt cf_hearing_body': this.props.print
    });

    return <div>
      {!this.props.print &&
        <div>
          <div>
            <AutoSave
              save={this.save(worksheet, worksheetIssues)}
              spinnerColor={LOGO_COLORS.HEARINGS.ACCENT}
              isSaving={this.props.worksheetIsSaving}
              timeSaved={this.props.worksheetTimeSaved || now()}
              saveFailed={this.props.saveWorksheetFailed}
            />
            <WorksheetHeaderVeteranSelection
              openPdf={this.openPdf}
              history={this.props.history}
              save={this.save(worksheet, worksheetIssues)}
            />
          </div>
          {fetchingWorksheet ?
            <LoadingScreen spinnerColor={LOGO_COLORS.HEARINGS.ACCENT} message="Loading worksheet..." /> :
            <div className={wrapperClassNames}>
              {firstWorksheetPage}
              {secondWorksheetPage}
            </div>}
        </div>
      }
      {this.props.print &&
    <div className={printWrapperClassNames}>
      {firstWorksheetPage}
      {secondWorksheetPage}
    </div>
      }
      {!this.props.print &&
        <div className="cf-push-right">
          <Link
            onClick={this.openPdf(worksheet, worksheetIssues)}
            button="secondary">
          Save as PDF
          </Link>
        </div>
      }
    </div>;
  }
}

const mapStateToProps = (state) => ({
  worksheet: state.worksheet,
  worksheetAppeals: state.worksheetAppeals,
  worksheetIssues: state.worksheetIssues,
  saveWorksheetFailed: state.saveWorksheetFailed,
  worksheetIsSaving: state.worksheetIsSaving,
  worksheetTimeSaved: state.worksheetTimeSaved,
  fetchingWorksheet: state.fetchingWorksheet
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onContentionsChange,
  onEvidenceChange,
  onCommentsForAttorneyChange,
  toggleWorksheetSaving,
  setWorksheetTimeSaved,
  saveWorksheet,
  setWorksheetSaveFailedStatus,
  saveIssues,
  saveDocket
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheet);
