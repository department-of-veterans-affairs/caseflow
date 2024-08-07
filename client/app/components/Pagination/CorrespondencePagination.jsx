import React from 'react';
import PropTypes, { object } from 'prop-types';
import Table from '../Table';
import PaginationButton from './PaginationButton';

class CorrespondencePagination extends React.PureComponent {
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
      totalItems,
      currentItems,
    } = this.props;

    const beginningCaseNumber = totalItems === 0 ? 0 : ((currentPage * pageSize) - pageSize + 1);
    // If there are no pages, there is no data, so the range should be 0-0.
    // Otherwise, the end of the range is the previous amount of cases +
    // the amount of data in the current page.
    const endingCaseNumber = totalItems === 0 ? 0 : (beginningCaseNumber + currentItems - 1);
    // Create the range
    let currentCaseRange = `${beginningCaseNumber}-${endingCaseNumber}`;
    // Create the entire summary
    const paginationSummary = `Viewing ${currentCaseRange} of ${totalItems} total`;
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
          aria-label="Next page"
          disabled={currentPage === totalPages}
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
        <Table
          columns={this.props.columns}
          rowObjects={this.props.rowObjects}
          summary={this.props.summary}
          className={this.props.className}
          headerClassName={this.props.headerClassName}
          bodyClassName={this.props.bodyClassName}
          tbodyId={this.props.tbodyId}
          getKeyForRow={this.props.getKeyForRow}
        />
        <div className="cf-pagination-pages">
          {paginationButtons}
        </div>
      </div>
    );
  }
}

CorrespondencePagination.propTypes = {
  pageSize: PropTypes.number.isRequired,
  currentPage: PropTypes.number.isRequired,
  currentItems: PropTypes.number.isRequired,
  totalPages: PropTypes.number,
  totalItems: PropTypes.number,
  updatePage: PropTypes.func.isRequired,
  columns: PropTypes.func,
  summary: PropTypes.string,
  className: PropTypes.string,
  rowObjects: PropTypes.arrayOf(object).isRequired,
  headerClassName: PropTypes.string,
  bodyClassName: PropTypes.string,
  tbodyId: PropTypes.string,
  getKeyForRow: PropTypes.func
};

export default React.memo(CorrespondencePagination);
