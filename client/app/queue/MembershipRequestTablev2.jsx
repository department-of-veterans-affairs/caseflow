import React, { useState } from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import DropdownButton from '../components/DropdownButton';
import Table from '../components/Table';
import { constant } from 'lodash';
import { css } from 'glamor';

const rowHasExpandedNote = css({
  '> td': { border: 'none' },
});

const expandedNote = css({
  '> td': { borderTop: 'none' },
});

const MembershipRequestColumnDefinitions = (row) => {
  const [expanded, setExpanded] = useState(false);

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
  const normalColumnsDefinitions = [
    {
      header: 'User name',
      valueFunction: (request) => request.name
    },
    {
      header: 'Date requested',
      valueFunction: (request) => moment(request.requestedDate).format('MM/DD/YYYY')
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
      valueFunction: (request) => {
        if (request.note) {
          return <button onClick={() => setExpanded(!expanded)}>Click me!</button>;
        }

        return '';

      },
    },
  ];

  const noteColumnDefinition = [
    {
      header: '',
      valueFunction: (request) => {
        return <>
          <strong>REQUEST NOTE:</strong>
          <p>{request.note}</p>
        </>;
      },
      span: constant(4),
    },
  ];

  if (row && row.hasNote) {
    return noteColumnDefinition;
  }

  return normalColumnsDefinitions;
};

const MembershipRequestTableV2 = (props) => {

  const { requests } = props;

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
  const normalColumnsDefinitions = [
    {
      header: 'User name',
      valueFunction: (request) => request.name
    },
    {
      header: 'Date requested',
      valueFunction: (request) => moment(request.requestedDate).format('MM/DD/YYYY')
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
      valueFunction: (request) => {
        if (request.note) {
          return <button>Click me!</button>;
        }

        return '';

      },
    },
  ];

  const noteColumnDefinition = [
    {
      header: '',
      valueFunction: (request) => {
        return <>
          <strong>REQUEST NOTE:</strong>
          <p>{request.note}</p>
        </>;
      },
      span: constant(4),
    },
  ];

  // This is going to take the requests and add an additional row if the request has a note
  // Got to do some hacking in the column definitions to make this work now.
  const rowObjects = () => {

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

    if (row && row.hasNote) {
      return noteColumnDefinition;
    }

    return normalColumnsDefinitions;
  };

  return <>
    <h2>Attemped reuse of Table component</h2>
    <Table
      columns={columnDefinitions}
      // rowObjects={rowObjects(requests)}
      rowObjects={MembershipRequestColumnDefinitions(requests)}
    />
  </>;
};

MembershipRequestTableV2.propTypes = {
  requests: PropTypes.array,
};

export default MembershipRequestTableV2;
