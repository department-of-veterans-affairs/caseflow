import React, { useContext } from 'react';
import COPY from '../../../COPY';
import PropTypes from 'prop-types';
import { StateContext } from '../../intakeEdit/IntakeEditFrame';
import CheckboxGroup from '../../components/CheckboxGroup';
import { formatDateStr } from '../../util/DateUtil';
import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES';
import { css } from 'glamor';
import TextareaField from '../../components/TextareaField';
const issueListStyling = css({ marginTop: '0rem', marginLeft: '6rem' });

const ReviewAppealView = (props) => {
  const { serverIntake } = props;
  const { reason, setSelectedIssues, selectedIssues, setOtherReason, otherReason } = useContext(StateContext);
  const veteran = serverIntake.veteran.name;
  const streamdocketNumber = props.appeal.stream_docket_number;
  const claimantName = props.serverIntake.claimantName;
  const requestIssues = props.serverIntake.requestIssues;
  const docketType = props.serverIntake.docketType;
  const original_hearing_request_type = props.appeal.original_hearing_request_type;

  const onIssueChange = (evt) => {
    setSelectedIssues({ ...selectedIssues, [evt.target.name]: evt.target.checked });
  };


  const issueOptions = () => requestIssues.map((issue) => ({
    id: issue.id.toString(),
    label:
      <>
        <span>{issue.description}</span><br />
        <span>Benefit Type: {BENEFIT_TYPES[issue.benefit_type]}</span><br />
        <span>Decision Date: {formatDateStr(issue.approx_decision_date)}</span>
        <br /><br />
      </>
  }));

  const onOtherReasonChange = (otherReason) => {
    setOtherReason(otherReason);
  };

  return (
    <>
      <div>
        <h1 style={{ margin: '0px' }}>{COPY.SPLIT_APPEAL_REVIEW_TITLE}</h1>
        <span>{COPY.SPLIT_APPEAL_REVIEW_SUBHEAD}</span>
      </div> &ensp;
      <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'left' }}>
        <u>{COPY.SPLIT_APPEAL_REVIEW_REASONING_TITLE}</u> &ensp;
        <span style={{ flexBasis: '75%' }}>{reason}</span>
      </div>
      <br />
      {reason === 'Other' && (
        <TextareaField
          resizestyle={null}
          value={otherReason}
          onChange={onOtherReasonChange}
        />
      )}
      <br />
      <div className="review_appeal_table">
        <table>
          <tr>
            <th></th>
            <th> {COPY.TABLE_ORIGINAL_APPEAL}</th>
            <th> {COPY.TABLE_NEW_APPEAL} </th>
          </tr>
          <tr>
            <td>{COPY.TABLE_VETERAN}</td>
            <td>{veteran}</td>
            <td>{veteran}</td>
          </tr>
          <tr>
            <th>{COPY.APPELLANT}</th>
            <th> {claimantName}</th>
            <th> {claimantName} </th>
          </tr>
          <tr>
            <td>{COPY.TABLE_DOCKET_NUMBER}</td>
            <td>{streamdocketNumber}</td>
            <td>{streamdocketNumber}</td>
          </tr>
          <tr>
            <td>{COPY.TABLE_REVIEW_OPTION}</td>
            <td>{docketType}
            <div>
            {original_hearing_request_type}
            </div>
            <div>
            </div>
            </td>
            <td>"Date"</td>
            <td>"Held"</td>
            <td>"View hearing worksheet link"</td>
          </tr>
          <tr>
            <td>{COPY.TABLE_ISSUE}</td>
            <td>
              <ol>
                {requestIssues.map((issue) => {
                  return (
                    <li>
                      <p>{issue.description}</p>
                      <p>Benefit type: {issue.benefit_type}</p>
                      <p>Decision date: {issue.approx_decision_date}</p>
                    </li>
                  );
                })}
              </ol>
            </td>
            <td>
              <CheckboxGroup
                vertical
                name="issues"
                label={COPY.SPLIT_APPEAL_CREATE_SELECT_ISSUES_TITLE}
                hideLabel
                id="otherReason"
                values={selectedIssues}
                onChange={(val) => onIssueChange(val)}
                options={issueOptions()}
                styling={issueListStyling}
                optional
                disabled
              />
            </td>
          </tr>
          <tr>
          </tr>
        </table>
      </div>
    </>
  );
};

ReviewAppealView.propTypes = {
  serverIntake: PropTypes.object
};
export default ReviewAppealView;
