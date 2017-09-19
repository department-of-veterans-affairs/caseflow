import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import moment from 'moment';
import Link from '../components/Link';
import TextField from '../components/TextField';
import TextareaField from '../components/TextareaField';
import HearingWorksheetStream from './components/HearingWorksheetStream';


import {
  onRepNameChange,
  onWitnessChange,
  onContentionsChange,
  onMilitaryServiceChange,
  onEvidenceChange,
  onCommentsForAttorneyChange
       } from './actions/Dockets';

export class HearingWorksheet extends React.PureComponent {

  render() {
    let { worksheet } = this.props;
    let readerLink = `/reader/appeal/${worksheet.vacols_id}/documents`;

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
          <span className="saving">Saving...</span>
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
            <div>Docket Number:</div>
            <div>1234567</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-4">
            <div>Veteran's Age:</div>
            <div>{worksheet.veteran_age}</div>
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

        <div className="cf-hearings-worksheet-data">
          <h2 className="cf-hearings-worksheet-header">Relevant Documents</h2>
          <h4>Docs in eFolder: 80</h4>
          <p className="cf-appeal-stream-label">APPEAL STREAM 1</p>
          <div className="cf-hearings-worksheet-data-cell column-1">
            <div>NOD:</div>
            <div>01/01/1990</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-2">
            <div>Form 9:</div>
            <div>01/01/1990</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-3">
            <div>Prior BVA Decision:</div>
            <div>01/01/1990</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-4">
            <div>&nbsp;</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-5">
            <div>Docs since Certification:</div>
            <div>23</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-1">
            <div>SOC:</div>
            <div>01/01/1990</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-2">
            <div>Certification:</div>
            <div>01/01/1990</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-3">
            <div>SSOC:</div>
            <div>01/01/1990</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-4">
            <div>&nbsp;</div>
          </div>
        </div>

           <HearingWorksheetStream
              worksheetStreams={worksheet.streams}
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
          name="signup-1"
          href={`${readerLink}?category=case_summary`}
          button="primary">
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
  onCommentsForAttorneyChange
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheet);
