import React from 'react';
import FoundIcon from '../components/FoundIcon';
import NotFoundIcon from '../components/NotFoundIcon';

// TODO: refactor to use shared components where helpful
const DocumentsCheckTable = (props) => {

  return <div className="cf-table-wrap">
    <table className="usa-table-borderless cf-table-borderless"
      summary="Each row represents document mismatch">
      <caption className="usa-sr-only">
        This table compares received dates for forms stored in VACOLS and VBMS.
      </caption>

      <thead>
        <tr>
          <th><span className="usa-sr-only">Status</span>Found in VBMS?</th>
          <th>Document</th>
          <th>VACOLS date</th>
          <th>VBMS date</th>
        </tr>
      </thead>

      <tbody>
        <tr id="form9-match">
          <td>{props.form9Match ? <FoundIcon/> : <NotFoundIcon/>}</td>
          <td>Form 9</td>
          <td>{props.form9Date}</td>
          <td>{props.form9Date}</td>
        </tr>
        <tr id="nod-match">
          <td>{props.nodMatch ? <FoundIcon/> : <NotFoundIcon/>}</td>
          <td>NOD</td>
          <td>{props.nodDate}</td>
          <td>{props.nodDate}</td>
        </tr>
        <tr id="soc-match">
          <td>{props.socMatch ? <FoundIcon/> : <NotFoundIcon/>}</td>
          <td>SOC</td>
          <td>{props.socDate}</td>
          <td>{props.socDate}</td>
        </tr>
        {props.ssocDates.map((ssocDate, index) =>
          <tr id={`ssoc-${index + 1}-match`} key={index}>
            <td><FoundIcon/></td>
            <td>SSOC {index + 1}</td>
            <td>{ssocDate}</td>
            <td>{ssocDate}</td>
          </tr>
        )}
      </tbody>
    </table>
  </div>;
};

export default DocumentsCheckTable;
