import React, { Component } from 'react';
import Button from '../components/Button';
import { Link } from 'react-router-dom';
import { formatDate } from '../util/DateUtil';
import Table from '../components/Table';

const summary = 'Claims for manager review';

const rowObjects = [
  {
    veteran: 'John Smith',
    date_processed: '3/30/2018',
    form: 'Ramp Election',
    employee: 'Jane Smith',
    explanation: 'Air ors'
  },
  {
    veteran: 'Jada Smith',
    date_processed: '3/30/2081',
    form: 'Ramp Refiling',
    employee: 'Julia Smith',
    explanation: 'Can selled'
  }
];

const columns = [
  {
    header: 'Veteran',
    valueName: 'veteran'
  },
  {
    header: 'Date Processed',
    align: 'center',
    valueFunction: (claim) => formatDate(claim.date_processed)
  },
  {
    header: 'Form',
    valueName: 'form'
  },
  {
    header: 'Employee',
    valueName: 'employee'
  },
  {
    header: 'Explanation',
    valueName: 'explanation'
  }
];

export default class ClaimsForReview extends Component {
  render = () => {
    return <div className="cf-app-segment cf-app-segment--alt cf-manager-intakes">
      <div>
        <h1>Claims for manager review</h1>
        <p>
        This list shows claims that did not result in an End Product (EP)
        because the user canceled midway through processing, or did not finish
        establishing the claim after receiving an alert message. After an EP is
        successfully established, you can <a href="" className="cf-action-refresh">refresh</a> the
        page to update this list.
        </p>
      </div>

      <div classNames={['cf-push-right']}>
        <Link to="/stats">
          <Button linkStyling>View stats</Button>
        </Link>
        <Link to="/intake">
          <Button legacyStyling={false} classNames={['usa-button-secondary', 'cf-push-right']}>Begin intake</Button>
        </Link>
      </div>

      <Table
        columns={columns}
        rowObjects={rowObjects} // change to this.props.claims when data is working
        summary={summary}
        slowReRendersAreOk />
    </div>;
  }
}
