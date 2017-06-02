import React from 'react';
import PropTypes from 'prop-types';

import { connect } from 'react-redux';
import { jumpToPage } from './actions';
import { isValidNum } from './utils';
import TextField from '../components/TextField';

const ENTER_KEY = 'Enter';

export class PdfUIPageNumInput extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      pageNumber: 1
    };
  }

  componentWillUpdate = (nextProps) => {
    if (nextProps.currentPage !== this.props.currentPage) {
      this.setPageNumber(nextProps.currentPage);
    }
  }

  setPageNumber = (pageNumber) => {
    this.setState({
      pageNumber
    });
  }

  handleKeyPress = (event) => {
    if (event.key === ENTER_KEY) {
      const pageNumber = event.target.value;
      const newPageNumber = this.validatePageNum(pageNumber);

      if (newPageNumber) {
        this.props.jumpToPage(newPageNumber, this.props.docId);
        this.setState({
          pageNumber: newPageNumber
        });
      }
    }
  }

  validatePageNum = (pageNumber) => {
    if (!pageNumber || !isValidNum(pageNumber) ||
      (pageNumber < 1 || pageNumber > this.props.numPages)) {
      return this.props.currentPage;
    }

    return pageNumber;
  }

  handleOnChange = (value) => {
    this.setState({
      pageNumber: value
    });
  }

  render() {

    return (
    <div style={{ display: 'inline-block' }}>
      <TextField
        maxlength="10"
        name="page-progress-indicator-input"
        label="Page"
        onChange={this.handleOnChange.bind(this)}
        onKeyPress={this.handleKeyPress}
        value={this.state.pageNumber}
        required={false}
        className={['page-progress-indicator-input']}
      />
    </div>);
  }
}

PdfUIPageNumInput.propTypes = {
  currentPage: PropTypes.number,
  numPages: PropTypes.number,
  jumpToPage: PropTypes.func
};

const mapDispatchToProps = (dispatch) => ({
  jumpToPage(pageNumber, docId) {
    dispatch(jumpToPage(pageNumber, docId));
  }
});

export default connect(
  null, mapDispatchToProps
)(PdfUIPageNumInput);
