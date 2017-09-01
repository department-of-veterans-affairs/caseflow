import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import Table from '../components/Table';
import Checkbox from '../components/Checkbox';
import moment from 'moment';
import Button from '../components/Button';
import TextField from '../components/TextField';
import TextareaField from '../components/TextareaField';
import HearingWorksheetStream from './components/HearingWorksheetStream';

import {
  onDescriptionsChange,
  onRepNameChange,
  onWitnessChange,
  onContentionsChange,
  onPeriodsChange,
  onEvidenceChange,
  onCommentsChange
       } from './actions/Dockets';

import _ from 'lodash';

export class HearingWorksheet extends React.PureComponent {


  getType = (type) => {
    return (type === 'central_office') ? 'CO' : type;
  }

  getStartTime = () => {
    const startTime = `${moment().
      add(_.random(0, 120), 'minutes').
      format('LT')} EST`;

    return startTime.replace('AM', 'a.m.').replace('PM', 'p.m.');
  }


  render() {
   // TODO <HearingWorksheetStream />



    return <div>
      <div className="cf-app-segment--alt cf-hearings-worksheet">

        <div className="cf-title-meta-right">
          <div className="title cf-hearings-title-and-judge">
            <h1>Hearing Worksheet</h1>
            <span>VLJ: {this.props.veteran_law_judge.full_name}</span>
          </div>
          <div className="meta">
            <div>{moment(this.props.date).format('ddd l')}</div>
            <div>Hearing Type: {this.props.hearingType}</div>
          </div>
        </div>

        <div className="cf-hearings-worksheet-data">
          <h2 className="cf-hearings-worksheet-header">Appellant/Veteran Information</h2>
          <span className="saving">Saving...</span>
          <div className="cf-hearings-worksheet-data-cell column-1">
            <div>Appellant Name:</div>
            <div><b>Somebody Mad</b></div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-2">
            <div>City/State:</div>
            <div>Lansing, MI</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-3">
            <div>Regional Office:</div>
            <div>Detroit, MI</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-4">
            <div>Representative Org:</div>
            <div>Veterans of Foreign Wars</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-5">
            <TextField
              name="Rep. Name:"
              id="appellant-vet-rep-name"
              aria-label="Representative Name"
              value={this.props.worksheet.repName || ''}
              onChange={this.props.onRepNameChange}
             />
          </div>
          <div className="cf-hearings-worksheet-data-cell column-1">
            <div>Veteran Name:</div>
            <div><b>Somebody Madder</b></div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-2">
            <div>Veteran ID:</div>
            <div><b>{this.props.vbms_id}</b></div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-3">
            <div>Docket Number:</div>
            <div>1234567</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-4">
            <div>Veteran's Age:</div>
            <div>32</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-5">
             <TextField
                name="Witness (W)/Observer (O):"
                id="appellant-vet-witness"
                aria-label="Representative Name"
                value={this.props.worksheet.witness || ''}
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

<HearingWorksheetStream />
      </div>
      <div className="cf-push-right">
        <Button name="signup-1" className="cf-push-right">Review eFolder</Button>
      </div>


    </div>;
  }
}

const mapStateToProps = (state) => ({
  worksheet: state.worksheet
});

// TODO to move the default value to the backend
const mapDispatchToProps = (dispatch) => bindActionCreators({
  onDescriptionsChange,
  onRepNameChange,
  onWitnessChange,
  onContentionsChange,
  onPeriodsChange,
  onEvidenceChange,
  onCommentsChange
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheet);

HearingWorksheet.propTypes = {
  veteran_law_judge: PropTypes.object.isRequired,
  date: PropTypes.string,
  vbms_id: PropTypes.string
};
