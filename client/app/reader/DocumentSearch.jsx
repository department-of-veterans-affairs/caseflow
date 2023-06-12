import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';

import { connect } from 'react-redux';
import { getTextForFile, getTotalMatchesInFile, getCurrentMatchIndex } from './selectors';
import SearchBar from '../components/SearchBar';
import { LeftChevronIcon } from '../components/icons/LeftChevronIcon';
import { RightChevronIcon } from '../components/icons/RightChevronIcon';
import Button from '../components/Button';
import { hideSearchBar, showSearchBar } from './PdfViewer/PdfViewerActions';
import { searchText, getDocumentText, updateSearchIndex, setSearchIndexToHighlight, setSearchIndex, setSearchIsLoading
} from '../reader/PdfSearch/PdfSearchActions';
import _ from 'lodash';
import classNames from 'classnames';
import { LOGO_COLORS } from '../constants/AppConstants';
import { recordMetrics } from '../util/Metrics';

export class DocumentSearch extends React.PureComponent {
  constructor() {
    super();

    this.searchTerm = '';
    this.sentAction = {};
  }

  getText = () => {
    if (this.props.pdfDocument &&
        // eslint-disable-next-line no-underscore-dangle
        !this.props.pdfDocument._transport.destroyed &&
        !this.sentAction[this.props.file] &&
        !_.isEmpty(this.searchTerm) &&
        _.isEmpty(this.props.pdfText)) {
      this.props.setSearchIsLoading(true);
      this.props.getDocumentText(this.props.pdfDocument, this.props.file);
      this.sentAction[this.props.file] = true;
    }
  }

  onChange = (value) => {
    this.searchTerm = value;

    this.getText();

    const metricData = {
      message: `Searching within Reader document ${this.props.file} for "${this.searchTerm}"`,
      type: 'performance',
      product: 'reader',
      data: {
        searchTerm: this.searchTerm,
        file: this.props.file,
      },
    };

    // todo: add guard to PdfActions.searchText to abort if !searchTerm.length
    recordMetrics(this.props.searchText(this.searchTerm), metricData,
      this.props.featureToggles.metricsRecordDocumentSearch);
  }

  updateSearchIndex = (iterateForwards) => {
    if (this.props.matchIndexToHighlight === null) {
      this.props.updateSearchIndex(iterateForwards);
    } else {
      this.props.setSearchIndex(this.props.matchIndexToHighlight);
      this.props.setSearchIndexToHighlight(null);
    }
  }

  onKeyPress = (event) => {
    if (event.key === 'Enter') {
      this.updateSearchIndex(!event.shiftKey);
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
      this.updateSearchIndex(!event.shiftKey);
    }

    if (event.key === 'Escape') {
      event.preventDefault();
      this.props.hideSearchBar();
    }

    if (event[metaKey] && event.code === 'KeyF') {
      this.props.showSearchBar();
      this.searchBar.setInputFocus();
      event.preventDefault();
    }
  }

  componentDidUpdate = (prevProps) => {
    // if focus is set on a hidden element, we can't prevent default
    // ctrl+f behavior, and other window-bound shortcuts stop working
    if (this.props.hidden) {
      this.searchBar.releaseInputFocus();
    } else if (prevProps.hidden) {
      // only hijack focus on show searchbar
      this.searchBar.setInputFocus();
    }

    if (this.props.file !== prevProps.file) {
      this.clearSearch();
    }

    const searchIsLoading = !this.props.pdfText.length && this.searchTerm.length > 0;

    if (this.props.searchIsLoading !== searchIsLoading) {
      this.props.setSearchIsLoading(searchIsLoading);
    }

    if (prevProps.pdfDocument !== this.props.pdfDocument) {
      this.getText();
    }
  }

  componentDidMount = () => window.addEventListener('keydown', this.shortcutHandler)
  componentWillUnmount = () => window.removeEventListener('keydown', this.shortcutHandler)

  nextMatch = () => this.updateSearchIndex(true)
  prevMatch = () => this.updateSearchIndex(false)

  searchBarRef = (node) => this.searchBar = node

  getInternalText = () => {
    let internalText = '';

    if (_.size(this.searchTerm)) {
      if (this.props.totalMatchesInFile > 0) {
        internalText = `${this.props.currentMatchIndex + 1} of ${this.props.totalMatchesInFile}`;
      } else if (this.props.totalMatchesInFile > 9999) {
        internalText = `${this.props.currentMatchIndex + 1} of many`;
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
        loading={this.props.searchIsLoading}
        spinnerColor={LOGO_COLORS.READER.ACCENT}
      />
      <Button
        classNames={['cf-increment-search-match', 'cf-prev-match']}
        onClick={this.prevMatch}>
        <div style={{ transform: 'translateY(5px) translateX(-0.5rem)' }}>
          <LeftChevronIcon />
          <span className="usa-sr-only">Previous Match</span>
        </div>
      </Button>
      <Button
        classNames={['cf-increment-search-match', 'cf-next-match']}
        onClick={this.nextMatch}>
        <div style={{ transform: 'translateY(5px) translateX(-0.5rem)' }}>
          <RightChevronIcon />
          <span className="usa-sr-only">Next Match</span>
        </div>
      </Button>
    </div>;
  }
}

DocumentSearch.propTypes = {
  currentMatchIndex: PropTypes.number,
  file: PropTypes.string,
  getDocumentText: PropTypes.func,
  hidden: PropTypes.any,
  hideSearchBar: PropTypes.func,
  matchIndexToHighlight: PropTypes.any,
  pdfDocument: PropTypes.shape({
    _transport: PropTypes.shape({
      destroyed: PropTypes.any
    })
  }),
  pdfText: PropTypes.shape({
    length: PropTypes.any
  }),
  searchIsLoading: PropTypes.any,
  searchText: PropTypes.func,
  setSearchIndex: PropTypes.func,
  setSearchIndexToHighlight: PropTypes.func,
  setSearchIsLoading: PropTypes.func,
  showSearchBar: PropTypes.func,
  totalMatchesInFile: PropTypes.number,
  updateSearchIndex: PropTypes.func,
  featureToggles: PropTypes.object,
};

const mapStateToProps = (state, props) => ({
  searchIsLoading: state.searchActionReducer.searchIsLoading,
  pdfDocument: state.pdf.pdfDocuments[props.file],
  pdfText: getTextForFile(state, props),
  totalMatchesInFile: getTotalMatchesInFile(state, props),
  currentMatchIndex: getCurrentMatchIndex(state, props),
  matchIndexToHighlight: state.searchActionReducer.indexToHighlight,
  hidden: state.pdfViewer.hideSearchBar,
  textExtracted: !_.isEmpty(state.searchActionReducer.extractedText),
  featureToggles: props.featureToggles,
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    setSearchIsLoading,
    searchText,
    getDocumentText,
    updateSearchIndex,
    hideSearchBar,
    showSearchBar,
    setSearchIndex,
    setSearchIndexToHighlight
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(DocumentSearch);
