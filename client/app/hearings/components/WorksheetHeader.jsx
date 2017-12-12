import React from 'react';
import AutoSave from '../../components/AutoSave';
import moment from 'moment';
import TextField from '../../components/TextField';
import * as AppConstants from '../../constants/AppConstants';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import Textarea from 'react-textarea-autosize';

import { saveIssues } from '../actions/Issue';

import {
  toggleWorksheetSaving,
  setWorksheetSaveFailedStatus,
  onRepNameChange,
  onWitnessChange,
  saveWorksheet
} from '../actions/Dockets';

class WorksheetHeader extends React.PureComponent {
  onWitnessChange = (event) => this.props.onWitnessChange(event.target.value);

  save = (worksheet, worksheetIssues) => () => {
    this.props.toggleWorksheetSaving();
    this.props.setWorksheetSaveFailedStatus(false);
    this.props.saveWorksheet(worksheet);
    this.props.saveIssues(worksheetIssues);
    this.props.toggleWorksheetSaving();
  };

  render() {
    const {
      appellant,
      worksheet,
      worksheetIssues,
      veteranLawJudge
    } = this.props;

    let olderVeteran = worksheet.veteran_age > 74;

    return <div>
      <div className="cf-title-meta-right">
        <div className="title cf-hearings-title-and-judge">
          <h1>Hearing Worksheet</h1>
          <span>VLJ: {veteranLawJudge.full_name}</span>
        </div>
        <div className="meta">
          <div>{moment(worksheet.date).format('ddd l')}</div>
          <div>Hearing Type: {worksheet.request_type}</div>
        </div>
      </div>

      <div className="cf-hearings-worksheet-data">
        <h2 className="cf-hearings-worksheet-header">Appellant/Veteran Information</h2>
        {!this.props.print &&
            <AutoSave
              save={this.save(worksheet, worksheetIssues)}
              spinnerColor={AppConstants.LOADING_INDICATOR_COLOR_HEARINGS}
              isSaving={this.props.worksheetIsSaving}
              saveFailed={this.props.saveWorksheetFailed}
            />
        }
        <div className="cf-hearings-worksheet-data-cell column-1">
          <div>Appellant Name:</div>
          <div><b>{appellant}</b></div>
        </div>
        <div className="cf-hearings-worksheet-data-cell column-2">
          <div>City/State:</div>
          <div>{worksheet.appellant_city && worksheet.appellant_state ?
            `${worksheet.appellant_city}, ${worksheet.appellant_state}` : ''}</div>
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
            maxLength={30}
            fixedInput={this.props.print}
          />
        </div>
        <div className="cf-hearings-worksheet-data-cell column-1">
          <div>Veteran Name:</div>
          <div><b>{worksheet.veteran_mi_formatted}</b></div>
        </div>
        <div className="cf-hearings-worksheet-data-cell column-2">
          <div>Veteran ID:</div>
          <div><b>{worksheet.vbms_id.slice(0, -1)}</b></div>
        </div>
        <div className="cf-hearings-worksheet-data-cell column-3">
          <div>Veteran's Age:</div>
          <div className={olderVeteran && 'cf-red-text'}>{worksheet.veteran_age}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell column-4">
        </div>
        <div className="cf-hearings-worksheet-data-cell cf-hearings-worksheet-witness-cell column-5">
          <label htmlFor="appellant-vet-witness">Witness (W)/Observer (O):</label>
          {this.props.print ?
            <p>{worksheet.witness}</p> :
            <Textarea
              name="Witness (W)/Observer (O):"
              id="appellant-vet-witness"
              aria-label="Witness Observer"
              value={worksheet.witness || ''}
              onChange={this.onWitnessChange}
              maxLength={120}
            />
          }
        </div>
      </div>
    </div>;
  }
}
const mapStateToProps = (state) => ({
  worksheet: state.worksheet,
  worksheetIssues: state.worksheetIssues
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  toggleWorksheetSaving,
  onRepNameChange,
  onWitnessChange,
  saveWorksheet,
  setWorksheetSaveFailedStatus,
  saveIssues
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(WorksheetHeader);
