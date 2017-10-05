import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import moment from 'moment';
import Link from '../components/Link';
import TextField from '../components/TextField';
import TextareaField from '../components/TextareaField';
import HearingWorksheetStream from './components/HearingWorksheetStream';
import AutoSave from '../components/AutoSave';
import * as AppConstants from '../constants/AppConstants';
import ApiUtil from '../util/ApiUtil';
import { TOGGLE_SAVING, SET_EDITED_FLAG_TO_FALSE, SET_SAVE_FAILED } from './constants/constants';

// TODO Move all stream related to streams container
import HearingWorksheetDocs from './components/HearingWorksheetDocs';

import {
  onRepNameChange,
  onWitnessChange,
  onContentionsChange,
  onMilitaryServiceChange,
  onEvidenceChange,
  onCommentsForAttorneyChange
       } from './actions/Dockets';

export class HearingWorksheet extends React.PureComponent {

  saveWorksheet = () => {
    this.props.saveWorksheet(this.props.worksheet);
  };

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
            save={this.saveWorksheet}
            spinnerColor={AppConstants.LOADING_INDICATOR_COLOR_HEARINGS}
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
              value={worksheet.repName || ''}
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
             <TextareaField
                name="Witness (W)/Observer (O):"
                id="appellant-vet-witness"
                aria-label="Representative Name"
                value={worksheet.witness || ''}
                onChange={this.props.onWitnessChange}
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
            <TextareaField
              name="Contentions"
              value={worksheet.contentions || ''}
              onChange={this.props.onContentionsChange}
              id="worksheet-contentions"
              />
          </div>

          <div className="cf-hearings-worksheet-data">
            <TextareaField
              name="Periods and circumstances of service"
              value={worksheet.military_service || ''}
              onChange={this.props.onMilitaryServiceChange}
              id="worksheet-military-service"
              />
          </div>

          <div className="cf-hearings-worksheet-data">
            <TextareaField
              name="Evidence"
              value={worksheet.evidence || ''}
              onChange={this.props.onEvidenceChange}
              id="worksheet-evidence"
              />
          </div>

          <div className="cf-hearings-worksheet-data">
            <TextareaField
              name="Comments and special instructions to attorneys"
              value={worksheet.comments_for_attorney || ''}
              id="worksheet-comments-for-attorney"
              onChange={this.props.onCommentsForAttorneyChange}
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
  saveWorksheet: (worksheet) => () => {
    if (worksheet.edited) {
      dispatch({ type: TOGGLE_SAVING });

      dispatch({ type: SET_SAVE_FAILED, payload: { saveFailed: false } });

      console.log(worksheet);

      ApiUtil.patch(`/hearings/worksheets/${worksheet.id}`, { data: { worksheet } }).
      then(() => {
        },
        () => {
          dispatch({ type: SET_SAVE_FAILED,
            payload: { saveFailed: true } });
      });
      dispatch({ type: TOGGLE_SAVING });
    }
  }
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheet);
