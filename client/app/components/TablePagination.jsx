import React from 'react';
import PropTypes from 'prop-types';

import PaginationButton from './PaginationButton';

class TablePagination extends React.PureComponent {
  handleChange = (index) => {
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

  generatePaginationButton = (indexOfPage) => {
    return (
      <PaginationButton
        key={`pagination-button-${indexOfPage}`}
        currentPage={this.props.currentPage}
        index={indexOfPage}
        handleChange={this.handleChange} />
    );
  };

  generateBlankButton = (key) => {
    return <button disabled key={`blank-button-${key}`}>...</button>;
  };

  render() {
    const {
      paginatedData,
      currentPage,
      totalCasesCount
    } = this.props;
    const numberOfPages = paginatedData.length;

    // Render the pagination summary
    // Get previous number of cases so we can calculate the case range in
    // the pagination summary
    let previousCaseCount = 0;

    for (let i = 0; i < currentPage; i += 1) {
      previousCaseCount += paginatedData[i].length;
    }
    // If there are no pages, there is no data, so the range should be 0-0.
    // Otherwise, the beginning of the range is the previous amount of cases + 1
    const beginningCaseNumber = numberOfPages > 0 ? previousCaseCount + 1 : 0;
    // If there are no pages, there is no data, so the range should be 0-0.
    // Otherwise, the end of the range is the previous amount of cases + 
    // the amount of data in the current page.
    const endingCaseNumber = numberOfPages > 0 ?
      previousCaseCount + paginatedData[currentPage].length :
      0;
    // Create the range
    let currentCaseRange = `${beginningCaseNumber}-${endingCaseNumber}`;
    // Create the entire summary
    const paginationSummary = `Viewing ${currentCaseRange} of ${totalCasesCount} total cases`;
    // Render the page buttons
    let pageButtons = [];
    let paginationButtons = [];

    if (numberOfPages > 5) {
      const indexOfLastPage = numberOfPages - 1;
      const firstPageButton = this.generatePaginationButton(0);
      const lastPageButton = this.generatePaginationButton(indexOfLastPage);

      if (currentPage < 3) {
        pageButtons = [...Array(4)].map((number, index) =>
          this.generatePaginationButton(index)
        );
        pageButtons.push(this.generateBlankButton(1));
        pageButtons.push(lastPageButton);
      } else if (currentPage > numberOfPages - 4) {
        pageButtons.push(firstPageButton);
        pageButtons.push(this.generateBlankButton(1));

        const last4PageButtons = [...Array(4)].map((number, index) =>
          this.generatePaginationButton(numberOfPages - (4 - index))
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
      pageButtons = [...Array(numberOfPages)].map((number, index) =>
        this.generatePaginationButton(index)
      );
    }

    if (numberOfPages > 1) {
      paginationButtons.push(
        <button
          key="previous-button"
          disabled={currentPage === 0}
          onClick={() => this.handlePrevious()}>
          Previous
        </button>
      );
      paginationButtons = paginationButtons.concat(pageButtons);
      paginationButtons.push(
        <button
          key="next-button"
          disabled={currentPage === (numberOfPages - 1)}
          onClick={() => this.handleNext()}>
          Next
        </button>
      );
    }

    return (
      <div className="cf-pagination">
        <div className="cf-pagination-summary">
          {paginationSummary}
        </div>
        <div className="cf-pagination-pages">
          {paginationButtons}
        </div>
      </div>
    );
  }
}

TablePagination.propTypes = {
  currentPage: PropTypes.number.isRequired,
  paginatedData: PropTypes.arrayOf(PropTypes.array).isRequired,
  totalCasesCount: PropTypes.number.isRequired,
  updatePage: PropTypes.func.isRequired
};

export default TablePagination;
