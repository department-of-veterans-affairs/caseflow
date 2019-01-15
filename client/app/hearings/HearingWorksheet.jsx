import React from 'react';

import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import HearingWorksheetStream from './components/HearingWorksheetStream';
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
import CFRichTextEditor from '../components/CFRichTextEditor';
import DOMPurify from 'dompurify';
import Button from '../components/Button';

// TODO Move all stream related to streams container
import HearingWorksheetDocs from './components/HearingWorksheetDocs';

import {
  onSummaryChange,
  toggleWorksheetSaving,
  setWorksheetTimeSaved,
  setWorksheetSaveFailedStatus,
  saveWorksheet,
  saveDocket
} from './actions/Dockets';

import { saveIssues } from './actions/Issue';

const toolbar = {
  options: ['inline', 'fontSize', 'list', 'colorPicker'],
  inline: {
    inDropdown: false,
    options: ['bold', 'italic', 'underline']
  },
  fontSize: {
    options: [8, 9, 10, 11, 12, 14, 16, 18, 24, 30, 36, 48, 60, 72, 96]
  },
  list: {
    inDropdown: false,
    options: ['unordered', 'ordered']
  },
  colorPicker: {
    options: ['Text'],
    colors: ['rgb(0,0,0)', 'rgb(0,0,255)', 'rgb(255,0,0)']
  }
};

const DEFAULT_SUMMARY_VALUE = '<p><strong>Contentions</strong></p> <p></p>' +
  '<p></p> <p><strong>Evidence</strong></p> <p></p> <p></p> <p><strong>Comments' +
  ' and special instructions to attorneys</strong></span></p> <p></p> <p></p>';

class WorksheetFormEntry extends React.PureComponent {

  render() {
    const textAreaProps = {
      minRows: 3,
      maxRows: 5000,
      value: this.props.value || '',
      toolbar,
      ..._.pick(
        this.props,
        [
          'name',
          'onChange',
          'id',
          'label'
        ]
      )
    };

    return <div className="cf-hearings-worksheet-data">
      {this.props.print ?
        <React.Fragment>
          <label htmlFor={this.props.id}>{this.props.name}</label>
          <div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(this.props.value) }} />
        </React.Fragment> :
        <CFRichTextEditor {...textAreaProps} />}
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

  getWorksheetTitle = () => {
    const { worksheet } = this.props;

    return `${worksheet.veteran_first_name[0]}. ${worksheet.veteran_last_name}'s ${document.title}`;
  };

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

  onSummaryChange = (value) => this.props.onSummaryChange(value);

  render() {
    let { worksheet, worksheetIssues, fetchingWorksheet } = this.props;

    const worksheetHeader = <WorksheetHeader
      print={this.props.print}
    />;

    const firstWorksheetPage = <div className="cf-hearings-first-page">
      {worksheetHeader}
      <HearingWorksheetDocs {...this.props} />
      <HearingWorksheetStream {...this.props} print={this.props.print} />
      {this.props.print &&
        <WorksheetFooter
          veteranName={this.props.worksheet.veteran_fi_last_formatted}
        />
      }
    </div>;

    const secondWorksheetPage = <div className="cf-hearings-second-page">
      <form className="cf-hearings-worksheet-form">
        <WorksheetFormEntry
          name="Hearing Summary"
          value={this.props.worksheet.summary || DEFAULT_SUMMARY_VALUE}
          onChange={this.onSummaryChange}
          id="worksheet-hearing-summary"
          minRows={1}
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
          <Button
            classNames={['usa-button-secondary']}
            name="Save as PDF"
            onClick={this.openPdf(worksheet, worksheetIssues)}
            aria-label="Save as PDF"
          />
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
  onSummaryChange,
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
