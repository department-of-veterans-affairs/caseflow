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
          <td>{props.form9_match ? <FoundIcon/> : <NotFoundIcon/>}</td>
          <td>Form 9</td>
          <td>{props.form9_date}</td>
          <td>{props.form9_date}</td>
        </tr>
        <tr id="nod-match">
          <td>{props.nod_match ? <FoundIcon/> : <NotFoundIcon/>}</td>
          <td>NOD</td>
          <td>{props.nod_date}</td>
          <td>{props.nod_date}</td>
        </tr>
        <tr id="soc-match">
          <td>{props.soc_match ? <FoundIcon/> : <NotFoundIcon/>}</td>
          <td>SOC</td>
          <td>{props.soc_date}</td>
          <td>{props.soc_date}</td>
        </tr>
        {props.ssoc_dates.map((ssoc_date, index) =>
          <tr id={"ssoc-${index + 1}-match"} key={index}>
            <td><FoundIcon/></td>
            <td>SSOC {index + 1}</td>
            <td>{ssoc_date}</td>
            <td>{ssoc_date}</td>
          </tr>
        )}
      </tbody>
    </table>
  </div>;
};

export default DocumentsCheckTable;
