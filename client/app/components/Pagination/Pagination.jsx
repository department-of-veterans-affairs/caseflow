import React from 'react';
import PropTypes from 'prop-types';
import Table from 'app/components/Table';

import PaginationButton from './PaginationButton';

class Pagination extends React.PureComponent {
  handleChange = (index) => {
    this.props.updatePage(index);
  };

  // pagination button is zero-based but we are one-based so fake out the currentPage.
  currentPageIndex = () => {
    return this.props.currentPage - 1;
  }

  handleNext = () => {
    const nextPageIndex = this.currentPageIndex() + 1;

    this.props.updatePage(nextPageIndex);
  };

  handlePrevious = () => {
    const previousPageIndex = this.currentPageIndex() - 1;

    this.props.updatePage(previousPageIndex);
  };

  generatePaginationButton = (indexOfPage) => {
    return (
      <PaginationButton
        key={`pagination-button-${indexOfPage}`}
        currentPage={this.currentPageIndex()}
        index={indexOfPage}
        handleChange={this.handleChange} />
    );
  };

  generateBlankButton = (key) => {
    return <button disabled key={`blank-button-${key}`} aria-label="More Pages">...</button>;
  };

  render() {
    const {
      totalPages,
      currentPage,
      pageSize,
      totalCases,
      currentCases,
      searchValue
    } = this.props;

    // If there are no pages, there is no data, so the range should be 0-0.
    // Otherwise, the beginning of the range is the previous amount of cases + 1
    let beginningCaseNumber;

    if (searchValue) {
      beginningCaseNumber = totalCases === 0 ? 0 : 1;
    } else if (totalCases === 0) {
      beginningCaseNumber = 0;
    } else {
      // eslint-disable-next-line no-mixed-operators
      beginningCaseNumber = currentPage * pageSize - pageSize + 1;
    }
    // If there are no pages, there is no data, so the range should be 0-0.
    // Otherwise, the end of the range is the previous amount of cases +
    // the amount of data in the current page.
    let endingCaseNumber;

    if (searchValue) {
      endingCaseNumber = totalCases;
    } else if (totalCases === 0) {
      endingCaseNumber = 0;
    } else {
      endingCaseNumber = beginningCaseNumber + currentCases - 1;
    }
    // Create the range
    let currentCaseRange = `${beginningCaseNumber}-${endingCaseNumber}`;
    // Create the entire summary
    const paginationSummary = `Viewing ${currentCaseRange} of ${totalCases} total`;
    // Render the page buttons
    let pageButtons = [];
    let paginationButtons = [];

    if (totalPages > 5) {
      const indexOfLastPage = totalPages - 1;
      const firstPageButton = this.generatePaginationButton(0);
      const lastPageButton = this.generatePaginationButton(indexOfLastPage);

      if (currentPage < 3) {
        pageButtons = [...Array(4)].map((number, index) =>
          this.generatePaginationButton(index)
        );
        pageButtons.push(this.generateBlankButton(1));
        pageButtons.push(lastPageButton);
      } else if (currentPage > totalPages - 4) {
        pageButtons.push(firstPageButton);
        pageButtons.push(this.generateBlankButton(1));

        const last4PageButtons = [...Array(4)].map((number, index) =>
          this.generatePaginationButton(totalPages - (4 - index))
        );

        pageButtons = pageButtons.concat(last4PageButtons);
      } else {
        pageButtons.push(firstPageButton);
        pageButtons.push(this.generateBlankButton(1));
        pageButtons.push(this.generatePaginationButton(currentPage - 1));
        pageButtons.push(this.generatePaginationButton(currentPage));
        pageButtons.push(this.generatePaginationButton(currentPage + 1));
        pageButtons.push(this.generateBlankButton(2));
        pageButtons.push(lastPageButton);
      }
    } else {
      pageButtons = [...Array(totalPages)].map((number, index) =>
        this.generatePaginationButton(index)
      );
    }

    if (totalPages > 1) {
      paginationButtons.push(
        <button
          key="previous-button"
          aria-label="Previous Page"
          disabled={currentPage === 1}
          onClick={() => this.handlePrevious()}>
          Previous
        </button>
      );
      paginationButtons = paginationButtons.concat(pageButtons);
      paginationButtons.push(
        <button
          key="next-button"
          aria-label="Next Page"
          disabled={currentPage === totalPages}
          onClick={() => this.handleNext()}>
          Next
        </button>
      );
    }

    return (

      <div className="cf-pagination">
        { this.props.enableTopPagination && (<div className="cf-pagination-pages">
          {paginationButtons}
        </div>) }
        <div className="cf-pagination-summary">
          {paginationSummary}
        </div>
        {this.props.table}
        <div className="cf-pagination-pages">
          {paginationButtons}
        </div>
      </div>
    );
  }
}

Pagination.propTypes = {
  pageSize: PropTypes.number.isRequired,
  currentPage: PropTypes.number.isRequired,
  currentCases: PropTypes.number.isRequired,
  totalPages: PropTypes.number,
  totalCases: PropTypes.number,
  updatePage: PropTypes.func.isRequired,
  table: PropTypes.oneOfType([PropTypes.instanceOf(Table), PropTypes.object]),
  enableTopPagination: PropTypes.bool,
  searchValue: PropTypes.string
};

export default Pagination;
