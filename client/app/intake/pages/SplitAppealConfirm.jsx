import React, { useContext } from 'react';
import { StateContext } from '../../intakeEdit/IntakeEditFrame';
import COPY from '../../../COPY';

const SplitAppealConfirm = () => {
  const { reason } = useContext(StateContext);
  const data = [
    { col1: 'Veteran', col2: 'Some Custom Data', col3: 'Some Custom Data'},
    { col1: 'Appellant', col2: 'Some Custom Data', col3: 'Some Custom Data'},
    { col1: 'Docket Number', col2: 'Some Custom Data', col3: 'Some Custom Data'},
    { col1: 'Review Option', col2: 'Some Custom Data', col3: 'Some Custom Data'},
    { col1: 'Issues(s)', col2: 'Some Custom Data', col3: 'Some Custom Data'},
  ];

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

export default SplitAppealConfirm;
