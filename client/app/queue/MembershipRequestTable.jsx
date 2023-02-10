import React, { useEffect, useRef, useState } from 'react';
import PropTypes from 'prop-types';
import { DoubleArrowIcon } from '../components/icons/DoubleArrowIcon';
import moment from 'moment';
import DropdownButton from '../components/DropdownButton';
import Table from '../components/Table';
import { constant, countBy, set, values, cloneDeep } from 'lodash';
import Pagination from '../components/Pagination/Pagination';

const MembershipRequestTable = (props) => {

  const { requests = [], enablePagination = true } = props;

  const REQUESTS_PER_PAGE = 10;
  // const tbodyRef = useRef(null);
  // const animationTimeout = useTimeout();

  const initializePaginatedData = (membershipRequests) => {
    // Add the count based on page number instead of expanded
    const paginatedData = [];

    console.log('this should only be called once');

    for (let i = 0; i < membershipRequests.length; i += REQUESTS_PER_PAGE) {
      paginatedData.push(membershipRequests.slice(i, i + REQUESTS_PER_PAGE));
    }

    return paginatedData;
  };
  // What if I created an object hash that stores the expanded state based on the request id?
  const [expanded, setExpanded] = useState({});
  const [currentPage, setCurrentPage] = useState(0);

  const [pageExpandedCount, setPageExpandedCount] = useState({ 0: 0 });

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

    // tempArray[currentPage] = getRowObjects(requests);

    console.log('use Effect values');
    console.log(tempArray[currentPage]);
    console.log(getPaginatedRowObjects(tempArray[currentPage]));
    tempArray[currentPage] = getPaginatedRowObjects(tempArray[currentPage]);
    // getRowObjects(requests.slice(i, i + REQUESTS_PER_PAGE)
    // const newPage = getRowObjects(requests).slice(currentPage + (REQUESTS_PER_PAGE * currentPage), currentPage + REQUESTS_PER_PAGE + pageExpandedCount[currentPage]);

    // tempArray[currentPage] = newPage;
    setPaginatedRequests(tempArray);
  };

  const expandedCount = countBy(values(expanded)).true || 0;

  console.log(expandedCount);

  // console.log(expanded);

  useEffect(() => {
    // This needs to be changed to only update the current page index rather than the full thing
    // setPaginatedRequests(initializePaginatedData(getRowObjects(requests)));

    // The expansion isn't removing values anymore
    updatePaginatedData();
  }, [expanded]);

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

  // useEffect(() => {

  // }, [expanded, currentPage]);

  const toggleExpanded = (id) => {
    setExpanded({
      ...expanded,
      [id]: !expanded[id],
    });

    let numExpanded = pageExpandedCount[currentPage] || 0;

    if (expanded[id]) {
      // console.log('should be subtracting one?');
      numExpanded -= 1;
    } else {
      // console.log('should be adding one?');
      numExpanded += 1;
    }

    setPageExpandedCount({
      ...pageExpandedCount,
      [currentPage]: numExpanded
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

  // Paginate the Rows If there are more than 10 requests
  // TODO: This might not work if it's not the first page. Try it out with notes on the second page.
  // Also add a few more to test out page 3.
  // const paginateMembershipRequests = (membershipRequests) => {
  //   // const expandedPerPage = pageExpandedCount[currentPage] || 0;
  //   const casesPerPage = REQUESTS_PER_PAGE;
  //   const paginatedData = [];

  //   // Do something with this?
  //   // Do something with pageExpandedCount
  //   // pageExpandedCount

  //   // It currently recalculates this everytime which is stupid. Probably need to add a state variable for it.
  //   if (enablePagination) {
  //     // Add the count based on page number instead of expanded
  //     // for (let i = 0, page = 0; i < membershipRequests.length; i += casesPerPage + (pageExpandedCount[page] || 0)) {
  //     for (let i = 0, page = 0; i < membershipRequests.length; i += (casesPerPage + expandedCount)) {
  //       paginatedData.push(membershipRequests.slice(i, i + casesPerPage + (pageExpandedCount[page] || 0)));
  //       page += 1;
  //     }
  //   } else {
  //     paginatedData.push(membershipRequests);
  //   }

  //   return paginatedData;
  // };

  // const paginatedRowObjects = this.paginateRowObjects(rowObjects);
  // TODO: this currently messes up due to expanded rows taking up an extra spot in the pagination when it shouldn't
  // const paginatedRows = paginateMembershipRequests(getRowObjects(requests));
  // TODO: Implement this or just always make it paginated
  // rowObjects = rowObjects && rowObjects.length ? paginatedData[this.state.currentPage] : rowObjects;

  // console.log(getRowObjects(requests));
  // console.log(paginatedRows);
  // console.log(expanded);
  // console.log(pageExpandedCount);

  // Some pretty stupid pagination math because of the way the way the row notes are conditionally added to the table.
  let currentCasesCount;

  if (paginatedRequests[currentPage]) {
    // currentCasesCount = paginatedRows[currentPage].length;
    currentCasesCount = paginatedRequests[currentPage].length || 0;

    currentCasesCount = currentCasesCount > 10 ? 10 : currentCasesCount;

  } else {
    currentCasesCount = 0;
  }

  return <>
    <h2>{`View ${requests.length} pending requests`}</h2>
    <Table
      className="membership-request-table"
      columns={columnDefinitions}
      // rowObjects={paginatedRows[currentPage]}
      rowObjects={paginatedRequests[currentPage]}
      // rowObjects={getRowObjects(requests)}
      rowClassNames={setRowClassNames}
      // tbodyRef={tbodyRef}
    />
    <Pagination
      pageSize={REQUESTS_PER_PAGE}
      currentPage={currentPage + 1}
      // currentCases={requests ? paginatedRows[currentPage].length : 0}
      // currentCases={paginatedRows[currentPage] ? paginatedRows[currentPage].length : 0}
      currentCases={currentCasesCount}
      totalPages={paginatedRequests.length}
      totalCases={requests.length}
      updatePage={(newPage) => setCurrentPage(newPage)}
    />
  </>;
};

MembershipRequestTable.propTypes = {
  requests: PropTypes.array,
  enablePagination: PropTypes.bool,
};

export default MembershipRequestTable;
