import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';

import { connect } from 'react-redux';
import { getTextSearch, getTextForFile, getTotalMatchesInFile, getCurrentMatchIndex } from './selectors';
import SearchBar from '../components/SearchBar';
import { LeftChevron, RightChevron } from '../components/RenderFunctions';
import Button from '../components/Button';
import { searchText, getDocumentText, updateSearchIndex, toggleSearchBar } from './actions';
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
      this.props.toggleSearchBar();
    }
  }

  componentDidMount = () => window.addEventListener('keydown', this.shortcutHandler)
  componentWillUnmount = () => window.removeEventListener('keydown', this.shortcutHandler)

  nextMatch = () => this.props.updateSearchIndex(true)
  prevMatch = () => this.props.updateSearchIndex(false)

  render() {
    // todo: use built-in styles
    const style = {
      position: 'absolute',
      background: '#333B45',
      zIndex: '20',
      color: 'white',
      right: '2rem',
      borderBottomLeftRadius: '6px',
      borderBottomRightRadius: '6px',
      padding: '0.5rem 1rem 1rem 1rem'
    };

    let internalText = this.props.totalMatchesInFile > 0 ?
      `${this.props.getCurrentMatch} of ${this.props.totalMatchesInFile}` : ' ';

    const classes = classNames('cf-search-bar', {
      hidden: !this.props.visibility
    });

    return <div className={classes} style={style}>
      <SearchBar
        isSearchAhead={true}
        size="small"
        id="search-ahead"
        placeholder="Type to search..."
        onChange={this.onChange}
        onKeyPress={this.onKeyPress}
        internalText={internalText}
      />
      <Button
        classNames={['cf-increment-search-match', 'cf-prev-match']}
        // todo: better centering
        children={<div style={{ transform: 'translateY(3px) translateX(-0.5rem)' }}><LeftChevron/></div>}
        onClick={this.prevMatch}
      />
      <Button
        classNames={['cf-increment-search-match', 'cf-next-match']}
        children={<div style={{ transform: 'translateY(3px) translateX(-0.5rem)' }}><RightChevron/></div>}
        onClick={this.nextMatch}
      />
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
  visibility: state.readerReducer.ui.pdf.hideSearchBar
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    searchText,
    getDocumentText,
    updateSearchIndex,
    toggleSearchBar
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(DocumentSearch);
