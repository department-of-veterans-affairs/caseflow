import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';

import { connect } from 'react-redux';
import { getTextSearch, getTextForFile } from './selectors';
import SearchBar from '../components/SearchBar';
import { searchText, getDocumentText, updateSearchIndex } from './actions';
import _ from 'lodash';

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
      Found on pages: {this.props.pageTexts.map((page) => page.pageIndex).join(', ')}
      Index: {this.props.searchIndex}
    </div>;
  }
}

DocumentSearch.propTypes = {
  file: PropTypes.string
};

const mapStateToProps = (state, props) => ({
  searchIndex: state.readerReducer.documentSearchIndex,
  pdfDocument: state.readerReducer.pdfDocuments[props.file],
  pdfText: getTextForFile(state, props),
  pageTexts: getTextSearch(state, props)
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    searchText,
    getDocumentText,
    updateSearchIndex
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(DocumentSearch);
