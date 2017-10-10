import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import moment from 'moment';
import Link from '../components/Link';
import TextField from '../components/TextField';
import Textarea from 'react-textarea-autosize';
import HearingWorksheetStream from './components/HearingWorksheetStream';
import AutoSave from '../components/AutoSave';
import * as AppConstants from '../constants/AppConstants';

// TODO Move all stream related to streams container
import HearingWorksheetDocs from './components/HearingWorksheetDocs';
import { saveIssues } from './actions/Issue';

import {
  onRepNameChange,
  onWitnessChange,
  onContentionsChange,
  onMilitaryServiceChange,
  onEvidenceChange,
  onCommentsForAttorneyChange,
  toggleWorksheetSaving,
  saveWorksheet
       } from './actions/Dockets';

export class HearingWorksheet extends React.PureComponent {

  save = (worksheet) => () => {
    // TODO: These need to run synchronously.
    this.props.toggleWorksheetSaving();
    this.props.saveWorksheet(worksheet);
    this.props.saveIssues(worksheet);
    this.props.toggleWorksheetSaving();
  };

  onWitnessChange = (event) => this.props.onWitnessChange(event.target.value);
  onContentionsChange = (event) => this.props.onContentionsChange(event.target.value);
  onMilitaryServiceChange = (event) => this.props.onMilitaryServiceChange(event.target.value);
  onEvidenceChange = (event) => this.props.onEvidenceChange(event.target.value);
  onCommentsForAttorneyChange = (event) => this.props.onCommentsForAttorneyChange(event.target.value);

  render() {
    let { worksheet } = this.props;
    let readerLink = `/reader/appeal/${worksheet.appeal_vacols_id}/documents`;

    return <div>
      <div className="cf-app-segment--alt cf-hearings-worksheet">

        <div className="cf-title-meta-right">
          <div className="title cf-hearings-title-and-judge">
            <h1>Hearing Worksheet</h1>
            <span>VLJ: {this.props.veteran_law_judge.full_name}</span>
          </div>
          <div className="meta">
            <div>{moment(worksheet.date).format('ddd l')}</div>
            <div>Hearing Type: {worksheet.request_type}</div>
          </div>
        </div>

        <div className="cf-hearings-worksheet-data">
          <h2 className="cf-hearings-worksheet-header">Appellant/Veteran Information</h2>
          <AutoSave
            save={this.save(worksheet)}
            spinnerColor={AppConstants.LOADING_INDICATOR_COLOR_HEARINGS}
            isSaving={this.props.worksheetIsSaving}
            saveFailed={this.props.saveWorksheetFailed}
          />
          <div className="cf-hearings-worksheet-data-cell column-1">
            <div>Appellant Name:</div>
            <div><b>{worksheet.appellant_last_first_mi}</b></div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-2">
            <div>City/State:</div>
            <div>{worksheet.appellant_city}, {worksheet.appellant_state}</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-3">
            <div>Regional Office:</div>
            <div>{worksheet.regional_office_name}</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-4">
            <div>Representative Org:</div>
            <div>{worksheet.representative}</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-5">
            <TextField
              name="Rep. Name:"
              id="appellant-vet-rep-name"
              aria-label="Representative Name"
              value={worksheet.representative_name || ''}
              onChange={this.props.onRepNameChange}
             />
          </div>
          <div className="cf-hearings-worksheet-data-cell column-1">
            <div>Veteran Name:</div>
            <div><b>{worksheet.veteran_name}</b></div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-2">
            <div>Veteran ID:</div>
            <div><b>{worksheet.vbms_id}</b></div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-3">
            <div>Veteran's Age:</div>
            <div>{worksheet.veteran_age}</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-4">
          </div>
          <div className="cf-hearings-worksheet-data-cell cf-hearings-worksheet-witness-cell column-5">
             <label htmlFor="appellant-vet-witness">Witness (W)/Observer (O):</label>
             <Textarea
                name="Witness (W)/Observer (O):"
                id="appellant-vet-witness"
                aria-label="Witness Observer"
                value={worksheet.witness || ''}
                onChange={this.onWitnessChange}
             />
          </div>
        </div>

        <HearingWorksheetDocs
          {...this.props}
        />

        <HearingWorksheetStream
           worksheetStreams={worksheet.appeals_ready_for_hearing}
              {...this.props}
        />

        <form className="cf-hearings-worksheet-form">
          <div className="cf-hearings-worksheet-data">
            <label htmlFor="worksheet-contentions">Contentions</label>
            <Textarea
              name="Contentions"
              value={worksheet.contentions || ''}
              onChange={this.onContentionsChange}
              id="worksheet-contentions"
              minRows={3}
              />
          </div>

          <div className="cf-hearings-worksheet-data">
             <label htmlFor="worksheet-military-service">Periods and circumstances of service</label>
            <Textarea
              name="Periods and circumstances of service"
              value={worksheet.military_service || ''}
              onChange={this.onMilitaryServiceChange}
              id="worksheet-military-service"
              minRows={3}
              />
          </div>

          <div className="cf-hearings-worksheet-data">
          <label htmlFor="worksheet-evidence">Evidence</label>
            <Textarea
              name="Evidence"
              value={worksheet.evidence || ''}
              onChange={this.onEvidenceChange}
              id="worksheet-evidence"
              minRows={3}
              />
          </div>

          <div className="cf-hearings-worksheet-data">
             <label htmlFor="worksheet-comments-for-attorney">Comments and special instructions to attorneys</label>
            <Textarea
              name="Comments and special instructions to attorneys"
              value={worksheet.comments_for_attorney || ''}
              id="worksheet-comments-for-attorney"
              onChange={this.onCommentsForAttorneyChange}
              minRows={3}
              />
          </div>
        </form>
      </div>
      <div className="cf-push-right">
        <Link
          name="review-efolder"
          href={`${readerLink}?category=case_summary`}
          button="primary"
          target="_blank">
            Review eFolder</Link>
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  worksheet: state.worksheet
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onRepNameChange,
  onWitnessChange,
  onContentionsChange,
  onMilitaryServiceChange,
  onEvidenceChange,
  onCommentsForAttorneyChange,
  toggleWorksheetSaving,
  saveWorksheet,
  saveIssues
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheet);
