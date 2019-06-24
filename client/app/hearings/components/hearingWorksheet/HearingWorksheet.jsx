import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import HearingWorksheetStream from './HearingWorksheetStream';
import WorksheetHeader from './WorksheetHeader';
import classNames from 'classnames';
import AutoSave from '../../../components/AutoSave';
import { LOGO_COLORS } from '../../../constants/AppConstants';
import _ from 'lodash';
import WorksheetHeaderVeteranSelection from './WorksheetHeaderVeteranSelection';
import ContestedIssues from '../../../queue/components/ContestedIssues';
import { now } from '../../utils';
import { navigateToPrintPage, openPrintDialogue } from '../../../util/PrintUtil';
import WorksheetFooter from './WorksheetFooter';
import CFRichTextEditor from '../../../components/CFRichTextEditor';
import DOMPurify from 'dompurify';
import Button from '../../../components/Button';
import ContentSection from '../../../components/ContentSection';
import HearingWorksheetDocs from './HearingWorksheetDocs';

import {
  onSummaryChange,
  toggleWorksheetSaving,
  setWorksheetTimeSaved,
  setWorksheetSaveFailedStatus,
  saveWorksheet,
  saveIssue
} from '../../actions/hearingWorksheetActions';

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
    if (this.props.print) {
      openPrintDialogue();
    }
  }

  getWorksheetTitle = () => {
    const { worksheet } = this.props;

    return `${worksheet.veteran_first_name[0]}. ${worksheet.veteran_last_name}'s Hearing Worksheet`;
  };

  save = (worksheet, worksheetIssues) => () => {
    this.props.saveWorksheet(worksheet);
    _.forEach(worksheetIssues, (issue) => {
      if (issue.edited) {
        this.props.saveIssue(issue);
      }
    });
  };

  openPdf = (worksheet, worksheetIssues) => () => {
    Promise.resolve([this.save(worksheet, worksheetIssues)()]).then(navigateToPrintPage);
  };

  onSummaryChange = (value) => this.props.onSummaryChange(value);

  getLegacyHearingWorksheet = () => {
    return <div>
      <HearingWorksheetDocs {...this.props} />
      <HearingWorksheetStream {...this.props} print={this.props.print} />
    </div>;
  };

  getHearingWorksheet = () => {
    return <div className="cf-hearings-worksheet-data cf-hearings-worksheet-issues">
      <ContentSection
        header={<div>Issues</div>}
        content={<ContestedIssues
          requestIssues={_.values(this.props.worksheetIssues)}
          decisionIssues={[]}
          hearingWorksheet
        />}
      />
    </div>;
  };

  render() {
    let { worksheet, worksheetIssues } = this.props;

    const firstWorksheetPage = <div className="cf-hearings-first-page">
      <WorksheetHeader />
      {this.props.worksheet.docket_name === 'hearing' ? this.getHearingWorksheet() : this.getLegacyHearingWorksheet()}
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
            <WorksheetHeaderVeteranSelection />
          </div>
          <div className={wrapperClassNames}>
            {firstWorksheetPage}
            {secondWorksheetPage}
          </div>
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
  worksheet: state.hearingWorksheet.worksheet,
  worksheetAppeals: state.hearingWorksheet.worksheetAppeals,
  worksheetIssues: state.hearingWorksheet.worksheetIssues,
  saveWorksheetFailed: state.hearingWorksheet.saveWorksheetFailed,
  worksheetIsSaving: state.hearingWorksheet.worksheetIsSaving,
  worksheetTimeSaved: state.hearingWorksheet.worksheetTimeSaved
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onSummaryChange,
  toggleWorksheetSaving,
  setWorksheetTimeSaved,
  saveWorksheet,
  setWorksheetSaveFailedStatus,
  saveIssue
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheet);
