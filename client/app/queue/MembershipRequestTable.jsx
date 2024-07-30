import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { DoubleArrowIcon } from '../components/icons/DoubleArrowIcon';
import moment from 'moment';
import DropdownButton from '../components/DropdownButton';
import Table from '../components/Table';
import { constant, cloneDeep } from 'lodash';
import Pagination from '../components/Pagination/Pagination';

const MembershipRequestTable = (props) => {

  const { requests = [] } = props;

  const REQUESTS_PER_PAGE = 10;

  const initializePaginatedData = (membershipRequests) => {
    const paginatedData = [];

    for (let i = 0; i < membershipRequests.length; i += REQUESTS_PER_PAGE) {
      paginatedData.push(membershipRequests.slice(i, i + REQUESTS_PER_PAGE));
    }

    return paginatedData;
  };

  // State variable to store the expanded state. It is an object of the form { [request.id]: boolean }
  const [expanded, setExpanded] = useState({});
  const [currentPage, setCurrentPage] = useState(0);

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

  // Since we are modifying the current page paginated rows instead of all of them now
  const getPaginatedRowObjects = (rows) => {
    // Guard clause for empty rows.
    if (!rows) {
      return [];
    }
    const updatedRequests = rows.reduce((acc, request) => {
      // If it does not have a note add it to the list. If it has a note skip it to avoid duplicates.
      if (!request.hasNote) {
        acc.push(request);
      }

      if ((request.note && expanded[request.id]) && !request.hasNote) {
        acc.push({ ...request, hasNote: true });
      }

      return acc;
    }, []);

    return updatedRequests;
  };

  // Create a state variable to hold the paginated requests.
  const [paginatedRequests, setPaginatedRequests] = useState(initializePaginatedData(getRowObjects(requests)));

  const updatePaginatedData = () => {
    const tempArray = cloneDeep(paginatedRequests);

    tempArray[currentPage] = getPaginatedRowObjects(tempArray[currentPage]);
    setPaginatedRequests(tempArray);
  };

  // Updates the current page pagination data
  useEffect(() => {
    updatePaginatedData();
  }, [expanded]);

  // Update the state if the requests prop changes.
  useEffect(() => {
    setPaginatedRequests(initializePaginatedData(getRowObjects(requests)));
  }, [requests]);

  const toggleExpanded = (id) => {
    setExpanded({
      ...expanded,
      [id]: !expanded[id],
    });
  };

  const dropdownOptions = [
    {
      title: 'Approve',
      action: 'approved',
    },
    {
      title: 'Deny',
      action: 'denied',
    },
  ];

  const buildDropdownActions = (request) => {
    return dropdownOptions.map((obj) => {
      return { ...obj, value: `${request.id}-${obj.action}` };
    });
  };

  const MembershipRequestDropDown = () => <div>
    <span> Select action </span>
    <DoubleArrowIcon />
  </div>;

  // The normal column definitions for the request table row that is not the additional request note row.
  const normalColumnsDefinitions = [
    {
      header: 'User name',
      valueFunction: (request) => request.userNameWithCssId
    },
    {
      header: 'Date requested',
      valueFunction: (request) => moment(request.requestedDate).format('MM/DD/YYYY')
    },
    {
      header: 'Actions',
      valueFunction: (request) => {
        return <DropdownButton
          lists={buildDropdownActions(request)}
          label="Request actions"
          onClick={props.membershipRequestActionHandler}
        >
          <MembershipRequestDropDown />
        </DropdownButton>;
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

  // If it is a note row, return the request's note text and set the colspan to 4.
  const noteColumnDefinition = [
    {
      header: '',
      valueFunction: (request) => {
        return <div className="expanded-note">
          <strong>REQUEST NOTE:</strong>
          <p>{request.note}</p>
        </div>;
      },
      span: constant(4),
    },
  ];

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
    return rowObject.hasNote ? 'membership-request-expanded-note-row' : 'membership-request-row';
  };

  // Only count the rows without the hasNote property key since those aren't membership requests, but notes.
  let currentRequestsCount = 0;

  if (paginatedRequests[currentPage]) {
    currentRequestsCount = paginatedRequests[currentPage].filter((obj) => !obj.hasNote).length;
  }

  // Create a function for the pagination so it can be easily added above and below the table.
  const MembershipRequestPagination = () => {
    return <Pagination
      pageSize={REQUESTS_PER_PAGE}
      currentPage={currentPage + 1}
      currentCases={currentRequestsCount}
      totalPages={paginatedRequests.length}
      totalCases={requests.length}
      updatePage={(newPage) => setCurrentPage(newPage)}
    />;
  };

  return <>
    <h2>{`View ${requests.length} pending requests`}</h2>
    <MembershipRequestPagination />
    <Table
      className="membership-request-table"
      columns={columnDefinitions}
      rowObjects={paginatedRequests[currentPage] || []}
      rowClassNames={setRowClassNames}
      getKeyForRow={(_, { hasNote, id }) => hasNote ? `${id}-note` : `${id}`}
    />
    <MembershipRequestPagination />
  </>;
};

MembershipRequestTable.propTypes = {
  requests: PropTypes.array,
  enablePagination: PropTypes.bool,
  membershipRequestActionHandler: PropTypes.func.isRequired,
};

export default MembershipRequestTable;
