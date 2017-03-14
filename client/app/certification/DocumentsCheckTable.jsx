import React, { PropTypes } from 'react';
import Table from '../components/Table';
import NotFoundIcon from '../components/NotFoundIcon';

export default class DocumentsCheckTable extends React.Component {
  render() {
    return <div className="cf-table-wrap">
      <table className="usa-table-borderless cf-table-borderless" summary="Each row represents document mismatch">
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
            <td> <NotFoundIcon/> </td>
            <td> Form 9 </td>
            <td> 09/31/2099 </td>
            <td> Not found </td>
          </tr>
          <tr id="nod-match">
            <td> <NotFoundIcon/> </td>
            <td> NOD </td>
            <td> 04/10/2010 </td>
            <td> Not found </td>
          </tr>
          <tr id="soc-match">
            <td> <NotFoundIcon/> </td>
            <td> SOC </td>
            <td> 03/19/2007 </td>
            <td> Not found </td>
          </tr>
        </tbody>
      </table>
    </div>
  }
}
