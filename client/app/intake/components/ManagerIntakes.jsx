import React from 'react';
import Table from '../../components/Table';

export default class ManagerIntakes extends React.PureComponent {
  render = () => {
    const rowObjects = [
      { veteran: 'John Smith',
        date_processed: '3/30/2018',
        form: 'Ramp Election',
        employee: 'Jane Smith',
        explanation: 'Air ors'
      },
      { veteran: 'Jada Smith',
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
        valueName: 'date_processed'
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

    const rowClassNames = (rowObject) => {
      return '';
    };

    ]);

    const summary = 'Claims for manager review';

    return <div className="cf-manager-intakes">
      <h1>Claims for manager review</h1>
      <p>
      This list shows claims that did not result in an End Product (EP)
      because the user canceled midway through processing, or did not finish
      establishing the claim after receiving an alert message. After an EP is
      successfully established, you can refresh the page to update this list.
      </p>

      <Table columns={columns} rowObjects={rowObjects} rowClassNames={rowClassNames} summary={summary}
        slowReRendersAreOk />
    </div>;
  }
}
