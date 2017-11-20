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
  constructor() {
    super();

    this.searchTerm = '';
    this.sentAction = {};
    this.loading = false;
  }

  onChange = (value) => {
    this.searchTerm = value;

    if (_.isEmpty(this.props.pdfText) && !this.sentAction[this.props.file]) {
      this.loading = Boolean(this.searchTerm.length);
      this.props.getDocumentText(this.props.pdfDocument, this.props.file);
      this.sentAction[this.props.file] = true;
    }

    // todo: add guard to PdfActions.searchText to abort if !searchTerm.length
    this.props.searchText(this.searchTerm);
  }

  onKeyPress = (value) => {
    if (value.key === 'Enter') {
      this.props.updateSearchIndex(!value.shiftKey);
    }
  }

  shortcutHandler = (event) => {
    // handle global shortcuts:
    // -navigating between results
    // -closing search
    // -preventing native search widget
    const metaKey = navigator.appVersion.includes('Win') ? 'ctrlKey' : 'metaKey';

    if (event[metaKey] && event.code === 'KeyG') {
      event.preventDefault();
      this.props.updateSearchIndex(!event.shiftKey);
    }

    if (event.key === 'Escape') {
      event.preventDefault();
      this.props.hideSearchBar();
    }

    if (event[metaKey] && event.code === 'KeyF') {
      event.preventDefault();
    }
  }

  componentDidUpdate = (prevProps) => {
    // if focus is set on a hidden element, we can't prevent default
    // ctrl+f behavior, and other window-bound shortcuts stop working
    if (this.props.hidden) {
      this.searchBar.releaseInputFocus();
    } else {
      this.searchBar.setInputFocus();
    }

    if (this.props.file !== prevProps.file) {
      this.clearSearch();
    }

    this.loading = Boolean(!this.props.textExtracted && this.searchTerm.length);
  }

  componentDidMount = () => window.addEventListener('keydown', this.shortcutHandler)
  componentWillUnmount = () => window.removeEventListener('keydown', this.shortcutHandler)

  nextMatch = () => this.props.updateSearchIndex(true)
  prevMatch = () => this.props.updateSearchIndex(false)

  searchBarRef = (node) => this.searchBar = node

  getInternalText = () => {
    let internalText = '';

    if (_.size(this.searchTerm)) {
      if (this.props.totalMatchesInFile > 0) {
        internalText = `${this.props.getCurrentMatch + 1} of ${this.props.totalMatchesInFile}`;
      } else if (this.props.totalMatchesInFile > 9999) {
        internalText = `${this.props.getCurrentMatch + 1} of many`;
      } else {
        internalText = '0 of 0';
      }
    }

    return internalText;
  }

  clearSearch = () => {
    this.searchBar.clearInput();
    this.onChange('');
  }

  render() {
    const classes = classNames('cf-search-bar', {
      hidden: this.props.hidden
    });

    // todo: add spinner before document text loaded (GET_DOCUMENT_TEXT)
    return <div className={classes}>
      <SearchBar
        ref={this.searchBarRef}
        isSearchAhead
        size="small"
        id="search-ahead"
        placeholder="Type to search..."
        onChange={this.onChange}
        onKeyPress={this.onKeyPress}
        internalText={this.getInternalText()}
        loading={this.loading}
      />
      <Button
        classNames={['cf-increment-search-match', 'cf-prev-match']}
        onClick={this.prevMatch}>
        <div style={{ transform: 'translateY(5px) translateX(-0.5rem)' }}>
          <LeftChevron />
          <span className="usa-sr-only">Previous Match</span>
        </div>
      </Button>
      <Button
        classNames={['cf-increment-search-match', 'cf-next-match']}
        onClick={this.nextMatch}>
        <div style={{ transform: 'translateY(5px) translateX(-0.5rem)' }}>
          <RightChevron />
          <span className="usa-sr-only">Next Match</span>
        </div>
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
  hidden: state.readerReducer.ui.pdf.hideSearchBar,
  textExtracted: !_.isEmpty(state.readerReducer.extractedText)
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
