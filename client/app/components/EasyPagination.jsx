import React from 'react';
import Pagination from './Pagination';
import PropTypes from 'prop-types';

class EasyPagination extends React.PureComponent {
  updatePageHandler = (idx) => {
    let newPage = idx + 1;

    if (newPage !== this.props.pagination.current_page) {
      let newUrl = `${window.location.href.split('?')[0]}?page=${newPage}`;

      window.location = newUrl;
    }
  }

  render = () => {
    return <Pagination
      currentPage={this.props.pagination.current_page}
      currentCases={this.props.currentCases}
      totalCases={this.props.pagination.total_items}
      totalPages={this.props.pagination.total_pages}
      pageSize={this.props.pagination.page_size}
      updatePage={this.updatePageHandler} />;
  }
}

EasyPagination.propTypes = {
  currentCases: PropTypes.number.isRequired,
  pagination: PropTypes.object
};

export default EasyPagination;
