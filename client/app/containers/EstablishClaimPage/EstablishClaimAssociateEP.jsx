import React from 'react';

import Table from '../../components/Table';
import Button from '../../components/Button';
import { formatDate } from '../../util/DateUtil';

const TABLE_HEADERS = ['Decision Date', 'EP Code', 'Status', 'Select this EP'];

export default class AssociatePage extends React.Component {

  buildEPRow = (ep) => [
    formatDate(new Date(ep.claim_receive_date)),
    ep.claim_type_code,
    ep.status_type_code,
    <Button
        name="Assign to Claim"
        classNames={["usa-button-outline"]}
      />
  ];

  sortEP = (a, b) => {
    let date1 = new Date(a.claim_receive_date);
    let date2 = new Date(b.claim_receive_date);
    return date2.getTime() - date1.getTime();
  }

  render = function() {
    let eps = this.props.eps.sort(this.sortEP);
    return <div className="cf-app-segment cf-app-segment--alt">
        <h1>Create End Product</h1>

        <div className="usa-alert usa-alert-warning">
          <div className="usa-alert-body">
            <h3 className="usa-alert-heading">Existing EP</h3>
            <p className="usa-alert-text">We found one or more existing EP(s)
            created within 30 days of this decision date.
            Please review the existing EP(s) in the table below.
            Select one to assign to this claim or create a new EP.</p>
          </div>
        </div>

        <div className="usa-grid-full">
          <Table
            headers={TABLE_HEADERS}
            buildRowValues={this.buildEPRow}
            values={eps}
          />
        </div>
      </div>;
  };
}