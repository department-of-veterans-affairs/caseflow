import React, { useEffect, useRef, useState, useTimeout } from 'react';
import PropTypes from 'prop-types';
import { DoubleArrowIcon } from '../components/icons/DoubleArrowIcon';
import moment from 'moment';
import DropdownButton from '../components/DropdownButton';
import Table from '../components/Table';
import { constant } from 'lodash';

const MembershipRequestTable = (props) => {

  const { requests = [] } = props;

  // const tbodyRef = useRef(null);
  // const animationTimeout = useTimeout();

  // What if I created an object hash that stores the expanded state based on the request id?
  const [expanded, setExpanded] = useState({});

  // console.log(expanded);

  // useEffect(() => {
  //   // console.log(expanded);
  //   // console.log(expanded.values());
  //   // console.log(values(expanded));
  //   // console.log(some(expanded, (value) => value === true));
  //   // anyExpanded =

  //   if (some(expanded, (value) => value === true)) {
  //     tbodyRef.current.classList.add('testing');
  //   } else {
  //     tbodyRef.current.classList.remove('testing');
  //   }
  // }, [expanded]);

  const toggleExpanded = (id) => {
    setExpanded({
      ...expanded,
      [id]: !expanded[id],
    });
  };

  // TODO: Build this out for each request since the target will be based on the id for the MembershipRequest
  const dropdownOptions = [
    {
      title: 'Approve',
      target: '/approve' },
    {
      title: 'Deny',
      target: '/deny' },
  ];

  // TODO: Ask if the requests are supposed to be ordered by created at?
  // Right now it will be in order based on the id of the membership request
  // It just happens to also be sorted created date as well in most cases since it is set on object creation.

  // The normal column definitions for the request table row that is not the additional request note row.
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
          // label=<div style={{ display: 'inline-block', textAlign: 'center' }}><span style={{ display: 'inline-block' }}>Select Action</span><DoubleArrowIcon /></div>
          label=<div>Select action <span style={{ transform: "translate('0px', '3px')" }}><DoubleArrowIcon /></span></div>
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
            aria-expanded={Boolean(expanded[request.id])}
            aria-label="Show note">
          </button>;

        }

        return '';

      },
    },
  ];

  // If it is a note row return the request's note text and set the colspan to 4.
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

  // Set the row objects for the table based on if the request has a note or not.
  // If it has a note and is expanded, add an additional row in the table.
  // The expanded is set based on the expanded react state hook and the button click
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

  // The column defintion will change for the table cell for each row depending on whether the row/request
  // has the attribute hasNote which is set in the row objects based on the expanded state.
  const columnDefinitions = (row) => {

    if (row && row.hasNote) {
      return noteColumnDefinition;
    }

    return normalColumnsDefinitions;
  };

  // Conditionally set the row class name for css for note rows.
  const setRowClassNames = (rowObject) => {
    return rowObject.hasNote ? 'membership-request-expanded-note' : 'membership-request-row';
  };

  return <>
    <h2>{`View ${requests.length} pending requests`}</h2>
    <Table
      className="membership-request-table"
      columns={columnDefinitions}
      rowObjects={getRowObjects(requests)}
      rowClassNames={setRowClassNames}
      // tbodyRef={tbodyRef}
    />
  </>;
};

MembershipRequestTable.propTypes = {
  requests: PropTypes.array,
};

export default MembershipRequestTable;
