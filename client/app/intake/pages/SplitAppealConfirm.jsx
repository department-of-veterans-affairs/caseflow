import React, { useContext } from 'react';
import { StateContext } from '../../intakeEdit/IntakeEditFrame';
import COPY from '../../../COPY';
import PropTypes from 'prop-types';

const SplitAppealConfirm = (props) => {
  const { serverIntake } = props;
  const requestIssues = serverIntake.requestIssues;
  const { selectedIssues, reason } = useContext(StateContext);

  return (
    <>
      <div>
        <h1 style={{ margin: '0px' }}>{COPY.SPLIT_APPEAL_REVIEW_TITLE}</h1>
        <span>{COPY.SPLIT_APPEAL_REVIEW_SUBHEAD}</span>
      </div>
      <br /><br />
      <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'left' }}>
        <u>{COPY.SPLIT_APPEAL_REVIEW_REASONING_TITLE}</u> &ensp;
        <span style={{ flexBasis: '75%' }}>{reason}</span>
        <span style={{ flexBasis: '75%' }}>{selectedIssues.selectValue.value}</span>
      </div>
      <div className="review_appeal_table">
        <table>
          <tr>
            <th></th>
            <th> {COPY.TABLE_ORIGINAL_APPEAL}</th>
            <th> {COPY.TABLE_NEW_APPEAL} </th>
          </tr>
          <tr>
            <td>{COPY.TABLE_VETERANT}</td>
            <td>{serverIntake.veteran.name}</td>
            <td>{serverIntake.veteran.name}</td>
          </tr>
          <tr>
            <td>{COPY.TABLE_DOCKET_NUMBER}</td>
            <td> { } </td>
            <td> </td>
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
                let valueIncrese = 1;

                return (
                  <ol type ={valueIncrese}>
                    <li>
                      <p>{issue.category}</p>
                      <p>Benefit type: {issue.benefit_type}</p>
                      <p>Decision date: {issue.approx_decision_date}</p>
                    </li>
                  </ol>
                );
              })}
            </td>
            <td>
              {selectedIssues.selectValue.value}
            </td>
          </tr>

        </table>
      </div>
      <br /><br />
      <p>The table currently dynamically renders data from an array.
        The Array.map() method allows you to iterate over an array and modify
        its elements using a callback function.The callback function will then
        be executed on each of the array’s elements. In this case, we will just
        return a table row on each iteration</p>
      <div className="App">
        <table>
          <tr>
            <th></th>
            <th>Original Appeal Stream</th>
            <th>New Appeal Stream</th>
          </tr>
          {data.map((val, key) => {
            return (
              <tr key={key}>
                <td>{val.col1}</td>
                <td>{val.col2}</td>
                <td>{val.col3}</td>
              </tr>
            );
          })}
        </table>
      </div>
    </>
  );
};

SplitAppealConfirm.propTypes = {
  serverIntake: PropTypes.object
};

export default SplitAppealConfirm;
