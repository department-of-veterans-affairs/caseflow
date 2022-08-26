import React, { useContext } from 'react';
import COPY from '../../../COPY';
import PropTypes from 'prop-types';
import { StateContext } from '../../intakeEdit/IntakeEditFrame';

const ReviewAppealView = (props) => {
  const { serverIntake } = props;
  const { reason } = useContext(StateContext);
  const veteran = serverIntake.veteran.name;
  const streamdocketNumber = props.appeal.stream_docket_number;
  const claimantName = props.serverIntake.claimantName;
  const requestIssues = props.serverIntake.requestIssues;

  {console.log(JSON.stringify(props.serverIntake))}    

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
            <td>"Hearing-Video"</td>
            <td>"Hearing-Video"</td>
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
