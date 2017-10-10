import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';

import { connect } from 'react-redux';
import { getTextSnippets } from './selectors';
import SearchBar from '../components/SearchBar';
import { setDocumentSearch } from './actions';

export class DocumentSearch extends React.PureComponent {
  render() {
    const style = {
      position: 'absolute',
      background: 'white',
      top: '0',
      bottom: '0',
      zIndex: '20'
    };

    const textDivs = this.props.textSnippets.map((snippet) => <p>{snippet.index} {snippet.sentence}</p>);

    return <div style={style}>
      <SearchBar
        onChange={this.props.setDocumentSearch}
      />
      {textDivs}
    </div>;
  }
}

const mapStateToProps = (state) => ({
  textSnippets: getTextSnippets(state.readerReducer),
  documentSearchString: state.readerReducer.documentSearchString
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    setDocumentSearch
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(DocumentSearch);
