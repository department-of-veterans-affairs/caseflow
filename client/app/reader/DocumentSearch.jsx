import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';

import { connect } from 'react-redux';
import { getTextSearch, getTextForFile, getTotalMatchesInFile, getCurrentMatchIndex } from './selectors';
import SearchBar from '../components/SearchBar';
import { LeftChevron, RightChevron } from '../components/RenderFunctions';
import Button from '../components/Button';
import { hideSearchBar } from './PdfViewer/PdfViewerActions';
import { searchText, getDocumentText, updateSearchIndex } from '../reader/Pdf/PdfActions';
import _ from 'lodash';
import classNames from 'classnames';

export class DocumentSearch extends React.PureComponent {
  onChange = (value) => {
    if (_.isEmpty(this.props.pdfText)) {
      this.props.getDocumentText(this.props.pdfDocument, this.props.file);
    }

    this.props.searchText(value);
  }

  onKeyPress = (value) => {
    if (value.key === 'Enter') {
      this.props.updateSearchIndex(!value.shiftKey);
    }
  }

  shortcutHandler = (event) => {
    const metaKey = navigator.appVersion.includes('Win') ? 'ctrlKey' : 'metaKey';

    if (event[metaKey] && event.code === 'KeyG') {
      event.preventDefault();
      this.props.updateSearchIndex(!event.shiftKey);
    }

    if (event.key === 'Escape') {
      this.props.hideSearchBar();
    }
  }

  componentDidUpdate = () => {
    // if focus is set on a hidden element, we can't prevent default
    // ctrl+f behavior, and other window-bound shortcuts stop working
    if (this.props.hidden) {
      this.searchBar.releaseInputFocus();
    } else {
      this.searchBar.setInputFocus();
    }
  }

  componentDidMount = () => window.addEventListener('keydown', this.shortcutHandler)
  componentWillUnmount = () => window.removeEventListener('keydown', this.shortcutHandler)

  nextMatch = () => this.props.updateSearchIndex(true)
  prevMatch = () => this.props.updateSearchIndex(false)

  searchBarRef = (node) => this.searchBar = node

  render() {
    const internalText = this.props.totalMatchesInFile > 0 ?
      `${this.props.getCurrentMatch + 1} of ${this.props.totalMatchesInFile}` : ' ';

    const classes = classNames('cf-search-bar', {
      hidden: this.props.hidden
    });

    return <div className={classes}>
      <SearchBar
        ref={this.searchBarRef}
        isSearchAhead
        size="small"
        id="search-ahead"
        placeholder="Type to search..."
        onChange={this.onChange}
        onKeyPress={this.onKeyPress}
        internalText={internalText}
      />
      <Button
        classNames={['cf-increment-search-match', 'cf-prev-match']}
        onClick={this.prevMatch}>
        <div style={{ transform: 'translateY(5px) translateX(-0.5rem)' }}><LeftChevron/></div>
      </Button>
      <Button
        classNames={['cf-increment-search-match', 'cf-next-match']}
        onClick={this.nextMatch}>
        <div style={{ transform: 'translateY(5px) translateX(-0.5rem)' }}><RightChevron/></div>
      </Button>
    </div>;
  }
}

DocumentSearch.propTypes = {
  file: PropTypes.string
};

const mapStateToProps = (state, props) => ({
  pdfDocument: state.readerReducer.pdfDocuments[props.file],
  pdfText: getTextForFile(state, props),
  pageTexts: getTextSearch(state, props),
  totalMatchesInFile: getTotalMatchesInFile(state, props),
  getCurrentMatch: getCurrentMatchIndex(state, props),
  hidden: state.readerReducer.ui.pdf.hideSearchBar
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    searchText,
    getDocumentText,
    updateSearchIndex,
    hideSearchBar
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(DocumentSearch);
