import React, { useState } from 'react';
import PropTypes, { object } from 'prop-types';
import CorrespondencePagination from '../../components/Pagination/CorrespondencePagination';
const CorrespondencePaginationWrapper = (props) => {
  const [currentPage, setCurrentPage] = useState(1);

  const totalPages = Math.ceil(props.rowObjects.length / props.columnsToDisplay);
  const startIndex = (currentPage * props.columnsToDisplay) - 15;
  const endIndex = (currentPage * props.columnsToDisplay);

  return <React.Fragment>
    <CorrespondencePagination
    // displayed label for beginning range of total items
      pageSize={props.columnsToDisplay}
      // index user  is on
      currentPage={currentPage}
      // displayed label for items on page
      currentItems={props.rowObjects.slice(startIndex, endIndex).length}
      // displayed pages user can click
      totalPages={totalPages}
      // displayed label for total items
      totalItems={props.rowObjects.length}
      columns={props.columns}
      rowObjects={props.rowObjects.slice(startIndex, endIndex)}
      summary={props.summary}
      className={props.className}
      headerClassName={props.headerClassName}
      bodyClassName={props.bodyClassName}
      tbodyId={props.tbodyId}
      getKeyForRow={props.getKeyForRow}
      updatePage={(incoming) => {
        setCurrentPage(incoming + 1);
      }}
    />
  </React.Fragment>;
};

CorrespondencePaginationWrapper.propTypes = {
  children: PropTypes.node,
  columnsToDisplay: PropTypes.number,
  rowObjects: PropTypes.arrayOf(object),
  columns: PropTypes.func,
  summary: PropTypes.string,
  className: PropTypes.string,
  headerClassName: PropTypes.string,
  bodyClassName: PropTypes.string,
  tbodyId: PropTypes.string,
  getKeyForRow: PropTypes.func
};

export default React.memo(CorrespondencePaginationWrapper);
