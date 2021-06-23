import React from 'react';
import { render, screen, within } from '@testing-library/react';
import { axe } from 'jest-axe';

import Table from 'app/components/Table';

const defaultProps = {
  columns: [
    {
      header: 'Task',
      valueName: 'task'
    },
    {
      header: 'Submitted',
      valueName: 'submitted'
    },
    {
      header: 'User',
      valueFunction: (rowObject) => {
        return `${rowObject.user.userFirstName.split('')[0]}. ${rowObject.user.userLastName}`;
      }
    }
  ],
  rowObjects: [
    {
      task: 'Task 1',
      submitted: '01/07/20',
      user: {
        userFirstName: 'Joe',
        userLastName: 'Doe'
      }
    },
    {
      task: 'Task 2',
      submitted: '02/17/20',
      user: {
        userFirstName: 'Sam',
        userLastName: 'Doe'
      }
    },
    {
      task: 'Task 3',
      submitted: '03/04/20',
      user: {
        userFirstName: 'Bob',
        userLastName: 'Doe'
      }
    },
    {
      task: 'Task 4',
      submitted: '03/10/20',
      user: {
        userFirstName: 'Van',
        userLastName: 'Doe'
      }
    }
  ]
};

describe('Table', () => {
  const setupComponent = (props = {}) => {
    return render(
      <Table {...defaultProps}{...props} summary="Test minimal table" slowReRendersAreOk />
    );
  };

  it('renders correctly', async () => {
    const { container } = setupComponent();

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = setupComponent();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  describe('rendering data', () => {
    it('displays row data using value function or value name', () => {
      setupComponent();

      for (let rowObject of defaultProps.rowObjects) {
        const userFirstName = rowObject.user.userFirstName.split('')[0];
        const userLastName = rowObject.user.userLastName;
        const rowUtil = within(screen.getByText(rowObject.task).closest('tr'));

        expect(rowUtil.getByText(rowObject.task)).toBeInTheDocument();
        expect(rowUtil.getByText(rowObject.submitted)).toBeInTheDocument();
        expect(rowUtil.getByText(`${userFirstName}. ${userLastName}`)).toBeInTheDocument();
      }
    });

    it('displays column data', () => {
      setupComponent();

      for (let column of defaultProps.columns) {
        const columnNameCell = within(screen.getByText(column.header).closest('tr'));

        expect(columnNameCell.getByText(column.header)).toBeInTheDocument();
      }
    });
  });
});
