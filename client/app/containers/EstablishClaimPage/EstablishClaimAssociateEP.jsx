import React from 'react';

import Table from '../../components/Table';
import Button from '../../components/Button';
import { formatDate } from '../../util/DateUtil';

const TABLE_HEADERS = ['Decision Date', 'EP Code', 'Status', 'Select this EP'];

const buildEPRow = (ep) => [
    formatDate(new Date(ep.claim_receive_date)),
    ep.claim_type_code,
    ep.status_type_code,
    <Button
      name="Assign to Claim"
      classNames={["usa-button-outline"]}
    />
  ];

export const render = function() {

  return <div className="cf-app-segment cf-app-segment--alt">
      <h1>Create End Product</h1>

      <div className="usa-alert usa-alert-warning">
        <div className="usa-alert-body">
          <h3 className="usa-alert-heading">Existing EP</h3>
          <p className="usa-alert-text">We found one or more existing EP(s) created within 30 days of this decision date.
          Please review the existing EP(s) in the table below. Select one to assign to this claim or create
          a new EP.</p>
        </div>
      </div>

      <div className="usa-grid-full">
        <Table
          headers={TABLE_HEADERS}
          buildRowValues={buildEPRow}
          values={this.state.associatedEPs}
        />
      </div>
    </div>;
};
