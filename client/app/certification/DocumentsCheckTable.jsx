import React from 'react';
import FoundIcon from '../components/FoundIcon';

// TODO: refactor to use shared components where helpful
const DocumentsCheckTable = () => {
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
          <td> <FoundIcon/> </td>
          <td> Form 9 </td>
          <td> 09/31/2099 </td>
          <td> Not found </td>
        </tr>
        <tr id="nod-match">
          <td> <FoundIcon/> </td>
          <td> NOD </td>
          <td> 04/10/2010 </td>
          <td> Not found </td>
        </tr>
        <tr id="soc-match">
          <td> <FoundIcon/> </td>
          <td> SOC </td>
          <td> 03/19/2007 </td>
          <td> Not found </td>
        </tr>
      </tbody>
    </table>
  </div>;
};

export default DocumentsCheckTable;
