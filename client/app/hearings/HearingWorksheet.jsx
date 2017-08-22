import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import Table from '../components/Table';
import Checkbox from '../components/Checkbox';
import moment from 'moment';
import Button from '../components/Button';
import TextareaField from '../components/TextareaField';
import {
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

  getKeyForRow = (index) => {
    return index;
  }

  // TODO to move the default value to the backend

  onContentionsChange = (contentions) => onContentionsChange(contentions)

  onPeriodsChange = (periods) => onPeriodsChange(periods)

  onEvidenceChange = (evidence) => onEvidenceChange(evidence)

  onCommentsChange = (comments) => onContentionsChange(comments)

  render() {

    const columns = [
      {
        header: '',
        valueName: 'counter'
      },
      {
        header: 'Program',
        align: 'left',
        valueName: 'program'
      },
      {
        header: 'Issue',
        align: 'left',
        valueName: 'issue'
      },
      {
        header: 'Levels 1-3',
        align: 'left',
        valueName: 'levels'
      },
      {
        header: 'Description',
        align: 'left',
        valueName: 'description'
      },
      {
        header: 'Preliminary Impressions',
        align: 'left',
        valueName: 'actions'
      }
    ];

    // temp
    const issues = [
      {
        program: 'Compensation',
        issue: 'Service connection',
        levels: 'All Others, 5010 - Arthritis, due to trauma',
        description: 'Right elbow',
        actions: [
          false, false, false, false, false, false
        ]
      },
      {
        program: 'Compensation',
        issue: 'Service connection',
        levels: 'All Others, 5242 - Degenerative arthritis of the spine (see also diagnostic code 5003)',
        description: 'Lower back',
        actions: [
          false, false, false, false, false, false
        ]
      },
      {
        program: 'Compensation',
        issue: 'Service connection',
        levels: 'All Others, 7799 - Other hemic or lymphatic system disability',
        description: 'Chronic bronchitis',
        actions: [
          false, false, false, false, false, false
        ]
      },
      {
        program: 'Compensation',
        issue: 'Service connection',
        levels: 'All Others, 8100 - Migraine',
        description: 'Frequent headaches',
        actions: [
          false, false, false, false, false, false
        ]
      }
    ];

    const rowObjects = issues.map((issue, index) => {
      return {
        counter: <b>{index + 1}.</b>,
        program: issue.program,
        issue: issue.issue,
        levels: issue.levels,
        description: <div>
          <label
            className="cf-hearings-worksheet-desc-label"
            htmlFor={`worksheet-issue-description-${index}`}>Description</label>
          <textarea defaultValue={issue.description}
            id={`worksheet-issue-description-${index}`}
            aria-label="Description"></textarea>
        </div>,
        actions: <div className="cf-hearings-worksheet-actions">
          <Checkbox
            label="Re-Open"
            name={`chk_reopen_${index}`}
            onChange={() => {
              return true;
            }}
            value={issue.actions[0]}
          ></Checkbox>
          <Checkbox
            label="Allow"
            name={`chk_allow_${index}`}
            onChange={() => {
              return true;
            }}
            value={issue.actions[1]}
          ></Checkbox>
          <Checkbox
            label="Deny"
            name={`chk_deny_${index}`}
            onChange={() => {
              return true;
            }}
            value={issue.actions[2]}
          ></Checkbox>
          <Checkbox
            label="Remand"
            name={`chk_remand_${index}`}
            onChange={() => {
              return true;
            }}
            value={issue.actions[3]}
          ></Checkbox>
          <Checkbox
            label="Dismiss"
            name={`chk_dismiss_${index}`}
            onChange={() => {
              return true;
            }}
            value={issue.actions[4]}
          ></Checkbox>
          <Checkbox
            label="VHA"
            name={`chk_vha_${index}`}
            onChange={() => {
              return true;
            }}
            value={issue.actions[5]}
          ></Checkbox>
        </div>
      };
    });

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
            <label htmlFor="appellant-vet-rep-name">Rep. Name:</label>
            <input id="appellant-vet-rep-name" aria-label="Representative Name" type="text" />
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
            <label htmlFor="appellant-vet-witness">Witness (W)/Observer (O):</label>
            <input id="appellant-vet-witness" aria-label="Witness/Observer" type="text" />
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

        <div className="cf-hearings-worksheet-data">
          <h2 className="cf-hearings-worksheet-header">Issues</h2>
          <p className="cf-appeal-stream-label">APPEAL STREAM 1</p>
          <Table
            className="cf-hearings-worksheet-issues"
            columns={columns}
            rowObjects={rowObjects}
            summary={'Worksheet Issues'}
            getKeyForRow={this.getKeyForRow}
          />
        </div>

        <form className="cf-hearings-worksheet-form">
          <div className="cf-hearings-worksheet-data">
            <TextareaField
              name="Contentions"
              value={this.props.worksheet.contentions || ''}
              onChange={this.props.onContentionsChange}
              id="worksheet-contentions"
              />
          </div>

          <div className="cf-hearings-worksheet-data">
            <TextareaField
              name="Periods and circumstances of service"
              value={this.props.worksheet.periods || ''}
              onChange={this.props.onPeriodsChange}
              id="worksheet-periods"
              />
          </div>

          <div className="cf-hearings-worksheet-data">
            <TextareaField
              name="Evidence"
              value={this.props.worksheet.evidence || ''}
              onChange={this.props.onEvidenceChange}
              id="worksheet-evidence"
              />
          </div>

          <div className="cf-hearings-worksheet-data">
            <TextareaField
              name="Comments and special instructions to attorneys"
              value={this.props.worksheet.comments || ''}
              id="worksheet-comments"
              onChange={this.props.onCommentsChange}
              />
          </div>
        </form>
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

const mapDispatchToProps = (dispatch) => bindActionCreators({
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
