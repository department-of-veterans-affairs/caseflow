import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';

import { connect } from 'react-redux';
import { getTextSearch, getTextForFile, getTotalMatchesInFile } from './selectors';
import SearchBar from '../components/SearchBar';
import { searchText, getDocumentText } from './actions';
import _ from 'lodash';

export class DocumentSearch extends React.PureComponent {
  onChange = (value) => {
    if (_.isEmpty(this.props.pdfText)) {
      this.props.getDocumentText(this.props.pdfDocument, this.props.file);
    }

    this.props.searchText(value);
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
      />
      Found on pages: {this.props.pageTexts.map((page) => page.pageIndex).join(', ')}<br/>
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
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    searchText,
    getDocumentText
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(DocumentSearch);
