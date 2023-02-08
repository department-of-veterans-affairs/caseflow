import React, { useState } from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import DropdownButton from '../components/DropdownButton';
import Table from '../components/Table';
import { constant } from 'lodash';

const MembershipRequestTableV2 = (props) => {

  const { requests } = props;

  // What if I created an object hash that stores the expanded state based on the request id?
  const [expanded, setExpanded] = useState({});

  // console.log(expanded);

  const toggleExpanded = (id) => {
    setExpanded({
      ...expanded,
      [id]: !expanded[id],
    });
  };

  // TODO: Build this out for each request since the target will be based on the id for the MembershipRequest
  // At least, I think that's how it might work later.
  const dropdownOptions = [
    {
      title: 'Approve',
      target: '/approve' },
    {
      title: 'Deny',
      target: '/deny' },
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
          return <button style={{ backgroundColor: 'inherit' }}
            onClick={() => toggleExpanded(request.id)}
            className="usa-accordion-button"
            aria-expanded={Boolean(expanded[request.id])}>
          </button>;

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
  const getRowObjects = (rows) => {

    const updatedRequests = rows.reduce((acc, request) => {
      acc.push(request);
      if (request.note && expanded[request.id]) {
        acc.push({ ...request, hasNote: true });
      }

      return acc;
    }, []);

    return updatedRequests;
  };

  // Have to do some serious crap here to make this work with the duplicated row objects
  const columnDefinitions = (row) => {

    if (row && row.hasNote) {
      return noteColumnDefinition;
    }

    return normalColumnsDefinitions;
  };

  const setRowClassNames = (rowObject) => {
    return rowObject.hasNote ? 'membership-request-expanded-note' : 'membership-request-row';
  };

  return <>
    <h2>Attemped reuse of Table component</h2>
    <h2>{`View ${requests.length} pending requests`}</h2>
    <Table
      className="membership-request-table"
      columns={columnDefinitions}
      rowObjects={getRowObjects(requests)}
      rowClassNames={setRowClassNames}
    />
  </>;
};

MembershipRequestTableV2.propTypes = {
  requests: PropTypes.array,
};

export default MembershipRequestTableV2;
