import React from 'react';
import PropTypes from 'prop-types';

class TablePagination extends React.PureComponent {
  handleClick = (event, index) => {
    this.props.updatePage(index);
  };

  handleNext = () => {
    const nextPageIndex = this.props.currentPage + 1;

    this.props.updatePage(nextPageIndex);
  };

  handlePrevious = () => {
    const previousPageIndex = this.props.currentPage - 1;

    this.props.updatePage(previousPageIndex);
  };

  render() {
    const {
      paginatedData,
      currentPage
    } = this.props;
    const numberOfPages = paginatedData.length;

    return (
      <div>
        <div className="cf-pagination-summary">
          Viewing {
            (currentPage * 15) + 1}-{(currentPage * 15) + 15
          } of {
            ((paginatedData.length - 1) * 15) + (paginatedData[paginatedData.length - 1].length)
          } total cases
        </div>
        <div className="cf-pagination-pages">
          <button
            disabled={currentPage === 0}
            onClick={this.handlePrevious}>
            Previous
          </button>
          {[...Array(numberOfPages)].map((number, index) =>
            <button
              key={index}
              onClick={(event) => this.handleClick(event, index)}
              className={currentPage === index ? 'cf-current-page' : ''}>
              {index + 1}
            </button>
          )}
          <button
            disabled={currentPage === (numberOfPages - 1)}
            onClick={this.handleNext}>
            Next
          </button>
        </div>
      </div>
    );
  }
}

TablePagination.propTypes = {
  currentPage: PropTypes.number.isRequired,
  paginatedData: PropTypes.arrayOf(PropTypes.array).isRequired,
  updatePage: PropTypes.func
};

export default TablePagination;
