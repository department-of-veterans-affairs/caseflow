import React, { useContext } from 'react';
import COPY from '../../../COPY';
import _ from 'lodash';
import PropTypes from 'prop-types';
import { StateContext } from '../../intakeEdit/IntakeEditFrame';

const ReviewAppealView = (props) => {
  const { serverIntake } = props;
  const requestIssues = serverIntake.requestIssues;
  const { reason } = useContext(StateContext);

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
            <td>{requestIssues.map((issue) => {
              return (
                <ol type ="1">
                  <li>
                    <p>{issue.category}</p>
                    <p>Benefit type: {issue.benefit_type}</p>
                    <p>Decision date: {issue.approx_decision_date}</p>
                  </li>
                </ol>
              );
            })}
            </td>
            <td>"Rosalia Turner"</td>
          </tr>
          <tr>
            <td>{COPY.TABLE_DOCKET_NUMBER}</td>
            <td>"191228-283"</td>
            <td>"191228-283"</td>
          </tr>
          <tr>
            <td>{COPY.TABLE_REVIEW_OPTION}</td>
            <td>"Hearing-Video"</td>
            <td>"Hearing-Video"</td>
          </tr>
          <tr>
            <td>{COPY.TABLE_ISSUE}</td>
            <td>
              {requestIssues.map((issue) => {
                return (
                  <ol type ="1">
                    <li>
                      <p>{issue.category}</p>
                      <p>Benefit type: {issue.benefit_type}</p>
                      <p>Decision date: {issue.approx_decision_date}</p>
                    </li>
                  </ol>
                );
              })}
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
