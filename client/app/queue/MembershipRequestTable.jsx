import React, { useEffect, useRef, useState } from 'react';
import PropTypes from 'prop-types';
import { DoubleArrowIcon } from '../components/icons/DoubleArrowIcon';
import moment from 'moment';
import DropdownButton from '../components/DropdownButton';
import Table from '../components/Table';
import { constant, countBy, values, cloneDeep } from 'lodash';
import Pagination from '../components/Pagination/Pagination';

const MembershipRequestTable = (props) => {

  const { requests = [], enablePagination = true } = props;

  const REQUESTS_PER_PAGE = 10;
  // const tbodyRef = useRef(null);
  // const animationTimeout = useTimeout();

  const initializePaginatedData = (membershipRequests) => {
    // Add the count based on page number instead of expanded
    const paginatedData = [];

    // console.log('this should only be called once');

    for (let i = 0; i < membershipRequests.length; i += REQUESTS_PER_PAGE) {
      paginatedData.push(membershipRequests.slice(i, i + REQUESTS_PER_PAGE));
    }

    return paginatedData;
  };
  // What if I created an object hash that stores the expanded state based on the request id?
  const [expanded, setExpanded] = useState({});
  const [currentPage, setCurrentPage] = useState(0);

  // const [pageExpandedCount, setPageExpandedCount] = useState({ 0: 0 });

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

  // Testing a new version of this to remove exisiting notes because it keeps adding them for paginated rows
  // Since we are modifying the current page paginated rows instead of all of them now
  const getPaginatedRowObjects = (rows) => {

    const updatedRequests = rows.reduce((acc, request) => {
      // Need to remove the existing notes everytime?
      if (request.hasNote) {
        // Ignore it
      } else {
        acc.push(request);
      }

      if ((request.note && expanded[request.id]) && !request.hasNote) {
        acc.push({ ...request, hasNote: true });
      }

      return acc;
    }, []);

    return updatedRequests;
  };

  // Next idea try to save the paged tasks to the state based on the current page so no need to recalculate it.
  const [paginatedRequests, setPaginatedRequests] = useState(initializePaginatedData(getRowObjects(requests)));

  const updatePaginatedData = () => {
    // TODO: Might not need this clone
    const tempArray = cloneDeep(paginatedRequests);

    tempArray[currentPage] = getPaginatedRowObjects(tempArray[currentPage]);
    setPaginatedRequests(tempArray);
  };

  // Updates the current page pagination data
  useEffect(() => {
    // This needs to be changed to only update the current page index rather than the full thing
    // setPaginatedRequests(initializePaginatedData(getRowObjects(requests)));
    updatePaginatedData();
  }, [expanded]);

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

  // TODO: Proptypes doesn't like this since label is "supposed" to be a string although it works.
  const MembershipRequestDropDownLabel = () => <div>
    <span> Select action </span>
    <DoubleArrowIcon />
  </div>;

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
          label=<MembershipRequestDropDownLabel />
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

  // Some pretty stupid pagination math because of the way the way the row notes are conditionally added to the table.
  let currentRequestsCount = 0;

  if (paginatedRequests[currentPage]) {
    currentRequestsCount = paginatedRequests[currentPage].length || 0;
    currentRequestsCount = currentRequestsCount > 10 ? 10 : currentRequestsCount;
  }

  const MembershipRequestPagination = () => {
    return <Pagination
      pageSize={REQUESTS_PER_PAGE}
      currentPage={currentPage + 1}
      // currentCases={requests ? paginatedRows[currentPage].length : 0}
      // currentCases={paginatedRows[currentPage] ? paginatedRows[currentPage].length : 0}
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
      // rowObjects={paginatedRows[currentPage]}
      rowObjects={paginatedRequests[currentPage]}
      // rowObjects={getRowObjects(requests)}
      rowClassNames={setRowClassNames}
      getKeyForRow={(_, { hasNote, id }) => hasNote ? `${id}-note` : `${id}`}
      // tbodyRef={tbodyRef}
    />
    <MembershipRequestPagination />
  </>;
};

MembershipRequestTable.propTypes = {
  requests: PropTypes.array,
  enablePagination: PropTypes.bool,
};

export default MembershipRequestTable;
