import React, { useState } from 'react';
import DropdownButton from '../components/DropdownButton';
import Table from '../components/Table';
import { constant } from 'lodash';

const MembershipRequestTableV2 = () => {

  const rowObjects = () => {
    // TODO: Retrieve these from the backend MembershipRequests for the current org
    const testTime = new Date().toLocaleDateString();
    const requests = [{ name: 'test 1', createdAt: testTime, note: 'This is an example reason of things and stuff.' },
      { name: 'test 2', createdAt: testTime, note: null }];

    return requests;
  };

  const columnDefinitions = (row) => {
    console.log(row);
    // TODO: Build this out for each request since the target will be based on the id for the MembershipRequest
    // At least, I think that's how it might work later.
    const dropdownOptions = [
      {
        title: 'Approve',
        target: '/approve' },
      {
        title: 'Deny',
        target: '/deny' }
    ];

    // TODO: Ask if this is supposed to be ordered by created at? I assume it is, but make sure and then order it.
    const columns = [
      {
        header: 'User name',
        valueFunction: (task) => task.name
      },
      {
        header: 'Date requested',
        valueFunction: (task) => task.createdAt
      },
      {
        header: 'Actions',
        valueFunction: () => {
          return <DropdownButton
            lists={dropdownOptions}
            // onClick={this.handleMenuClick}
            label="Select action"
          />;
        }
      },
      {
        header: '',
        valueFunction: (task) => {
          if (task.note) {
            return <button>Click me!</button>;
          }

          return '';

        },
        span: constant(4),
      },
    ];

    return columns;
  };

  return <>
    <h2>Attemped reuse of Table component</h2>
    <Table columns={columnDefinitions} rowObjects={rowObjects()} />
  </>;
};

export default MembershipRequestTableV2;
