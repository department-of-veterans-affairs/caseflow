import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import HearingWorksheetStream from './HearingWorksheetStream';
import WorksheetHeader from './WorksheetHeader';
import AutoSave from '../../../components/AutoSave';
import { LOGO_COLORS } from '../../../constants/AppConstants';
import _ from 'lodash';
import WorksheetHeaderVeteranSelection from './WorksheetHeaderVeteranSelection';
import ContestedIssues from '../../../queue/components/ContestedIssues';
import { now } from '../../utils';
import { navigateToPrintPage } from '../../../util/PrintUtil';
import { formatNameShort } from '../../../util/FormatUtil';
import { encodeQueryParams } from '../../../util/QueryParamsUtil';
import CFRichTextEditor from '../../../components/CFRichTextEditor';
import Button from '../../../components/Button';
import ContentSection from '../../../components/ContentSection';
import HearingWorksheetDocs from './HearingWorksheetDocs';
import ApiUtil from '../../../util/ApiUtil';

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

export const getWorksheetTitle = (worksheet) => (
  `${formatNameShort(worksheet.veteran_first_name, worksheet.veteran_last_name)}'s Hearing Worksheet`
);

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

    return (
      <div className="cf-hearings-worksheet-data">
        <CFRichTextEditor {...textAreaProps} />
      </div>
    );
  }
}

WorksheetFormEntry.propTypes = {
  value: PropTypes.any
};

export class HearingWorksheet extends React.PureComponent {
  componentDidMount() {
    document.title = getWorksheetTitle(this.props.worksheet);
    this.postHearingView();
  }

  postHearingView = () => {
    ApiUtil.post(`/hearings/hearing_view/${this.props.worksheet.external_id}`);
  }

  save = (worksheet, worksheetIssues) => () => {
    this.props.saveWorksheet(worksheet);
    _.forEach(worksheetIssues, (issue) => {
      if (issue.edited) {
        this.props.saveIssue(issue);
      }
    });
  };

  openPdf = (worksheet, worksheetIssues) => () => {
    Promise.resolve(
      [this.save(worksheet, worksheetIssues)()]
    ).then(
      () => {
        const queryString = encodeQueryParams(
          {
            hearing_ids: worksheet.external_id,
            keep_open: true
          }
        );

        navigateToPrintPage(`/hearings/worksheet/print${queryString}`);
      }
    );
  };

  onSummaryChange = (value) => this.props.onSummaryChange(value);

  getLegacyHearingWorksheet = () => {
    return (
      <div>
        <HearingWorksheetDocs {...this.props} />
        <HearingWorksheetStream {...this.props} />
      </div>
    );
  }

  getHearingWorksheet = () => {
    return (
      <div className="cf-hearings-worksheet-data cf-hearings-worksheet-issues">
        <ContentSection
          header={<div>Issues</div>}
          content={<ContestedIssues
            requestIssues={_.values(this.props.worksheetIssues)}
            decisionIssues={[]}
            hearingWorksheet
          />}
        />
      </div>
    );
  }

  render() {
    const { worksheet, worksheetIssues } = this.props;

    return (
      <div>
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
          <div className="cf-hearings-worksheet cf-app-segment--alt">
            <WorksheetHeader />
            {
              this.props.worksheet.docket_name === 'hearing' ?
                this.getHearingWorksheet() :
                this.getLegacyHearingWorksheet()
            }
            <form className="cf-hearings-worksheet-form">
              <WorksheetFormEntry
                name="Hearing Summary"
                value={this.props.worksheet.summary || DEFAULT_SUMMARY_VALUE}
                onChange={this.onSummaryChange}
                id="worksheet-hearing-summary"
                minRows={1}
              />
            </form>
          </div>
        </div>
        <div className="cf-push-right">
          <Button
            classNames={['usa-button-secondary']}
            name="Save as PDF"
            onClick={this.openPdf(worksheet, worksheetIssues)}
            aria-label="Save as PDF"
          />
        </div>
      </div>
    );
  }
}

HearingWorksheet.propTypes = {
  worksheet: PropTypes.shape({
    summary: PropTypes.string,
    docket_name: PropTypes.string,
    external_id: PropTypes.string
  }),
  worksheetIssues: PropTypes.array,
  saveWorksheetFailed: PropTypes.bool,
  worksheetTimeSaved: PropTypes.bool,
  worksheetIsSaving: PropTypes.bool,
  onSummaryChange: PropTypes.func,
  saveWorksheet: PropTypes.func,
  saveIssue: PropTypes.func
};

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
