import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';

import { connect } from 'react-redux';
import { getTextSearch, getTextForFile, getTotalMatchesInFile, getCurrentMatchIndex } from './selectors';
import SearchBar from '../components/SearchBar';
import { searchText, getDocumentText, updateSearchIndex } from '../reader/Pdf/PdfActions';
import _ from 'lodash';

export class DocumentSearch extends React.PureComponent {
  constructor() {
    super();
    
    this.sentAction = {};
  }

  onChange = (value) => {
    if (_.isEmpty(this.props.pdfText) && !this.sentAction[this.props.file]) {
      this.props.getDocumentText(this.props.pdfDocument, this.props.file);
      this.sentAction[this.props.file] = true;
    }

    this.props.searchText(value);
  }

  onKeyPress = (value) => {
    if (value.key === 'Enter') {
      this.props.updateSearchIndex(!value.shiftKey);
    }
  }

  render() {
    const style = {
      position: 'absolute',
      background: 'white',
      zIndex: '20'
    };

    return <div style={style}>
      <SearchBar
        onChange={this.onChange}
        onKeyPress={this.onKeyPress}
      />
      Found on pages: {this.props.pageTexts.map((page) => page.pageIndex).join(', ')}<br />
      Index: {this.props.getCurrentMatch}<br />
      Total matches: {this.props.totalMatchesInFile}
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
  getCurrentMatch: getCurrentMatchIndex(state, props)
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    searchText,
    getDocumentText,
    updateSearchIndex
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(DocumentSearch);
