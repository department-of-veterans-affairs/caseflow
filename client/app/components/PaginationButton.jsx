import React from 'react';
import PropTypes from 'prop-types';

class PaginationButton extends React.PureComponent {
  handleClick = (event, index) => {
    this.props.handleChange(index);
  };

  render() {
    const {
      currentPage,
      index
    } = this.props;

    return (
      <button
        key={index}
        onClick={(event) => this.handleClick(event, index)}
        className={currentPage === index ? 'cf-current-page' : ''}>
        {index + 1}
      </button>
    );
  }
}

PaginationButton.propTypes = {
  currentPage: PropTypes.number,
  handleChange: PropTypes.func,
  index: PropTypes.number
};

export default PaginationButton;
