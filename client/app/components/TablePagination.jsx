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
      currentPage
    } = this.props;
    const numberOfPages = paginatedData.length;
    let pageButtons = [];

    // Render the pagination summary
    let currentCaseRange;
    const totalCases = ((paginatedData.length - 1) * 15) + (paginatedData[paginatedData.length - 1].length);

    if (numberOfPages < 2) {
      currentCaseRange = `1-${totalCases}`;
    } else {
      currentCaseRange = `${(currentPage * 15) + 1}-${(currentPage * 15) + 15}`;
    }

    const paginationSummary = `Viewing ${currentCaseRange} of ${totalCases} total cases`;

    // Render the page buttons
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

    return (
      <div>
        <div className="cf-pagination-summary">
          {paginationSummary}
        </div>
        <div className="cf-pagination-pages">
          <button
            disabled={currentPage === 0}
            onClick={() => this.handlePrevious()}>
            Previous
          </button>
          {pageButtons}
          <button
            disabled={currentPage === (numberOfPages - 1)}
            onClick={() => this.handleNext()}>
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
