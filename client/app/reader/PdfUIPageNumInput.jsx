import React from 'react';
import PropTypes from 'prop-types';

import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { jumpToPage } from '../reader/PdfViewer/PdfViewerActions';
import { isValidWholeNumber } from './utils';
import TextField from '../components/TextField';

const ENTER_KEY = 'Enter';
const RADIX = 10;

export class PdfUIPageNumInput extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      pageNumber: 1
    };
  }

  UNSAFE_componentWillUpdate = (nextProps) => { // eslint-disable-line camelcase
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

      this.setPageNumber(newPageNumber);
      // don't jump to the page unless it's a valid page entry
      // and it's not the current page
      if (this.props.currentPage !== newPageNumber) {
        this.props.jumpToPage(newPageNumber, this.props.docId);
      }
    }
  }

  validatePageNum = (pageNumber) => {
    let pageNum = parseInt(pageNumber, RADIX);

    if (!pageNum || !isValidWholeNumber(pageNum) ||
      (pageNum < 1 || pageNum > this.props.numPages)) {
      return this.props.currentPage;
    }

    return pageNum;
  }

  render() {
    return (
      <div style={{ display: 'inline-block' }}>
        <TextField
          maxLength={4}
          name="page-progress-indicator-input"
          label="Page"
          onChange={this.setPageNumber}
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
  jumpToPage: PropTypes.func,
  docId: PropTypes.number
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  jumpToPage
}, dispatch);

export default connect(
  null, mapDispatchToProps
)(PdfUIPageNumInput);
