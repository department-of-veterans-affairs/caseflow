import React, { useState } from 'react';
import DropdownButton from '../components/DropdownButton';
import Table from '../components/Table';
import { constant } from 'lodash';

const MembershipRequestTableV2 = (props) => {

  // This is going to taket the requests and reduce them into a row object
  // Additionally it will add a row if the request has a note
  // Got to do some hacking in the column definitions to make this work now.
  const rowObjects = (requests) => {

    const updatedRequests = requests.reduce((acc, request) => {
      acc.push(request);
      if (request.note) {
        acc.push({ ...request, hasNote: true });
      }

      return acc;
    }, []);

    return updatedRequests;
  };

  // Have to do some serious crap here to make this work with the duplicated row objects
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
        valueFunction: (task) => task.requestedDate
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

  const { requests } = props;

  return <>
    <h2>Attemped reuse of Table component</h2>
    <Table columns={columnDefinitions} rowObjects={rowObjects(requests)} />
  </>;
};

export default MembershipRequestTableV2;
