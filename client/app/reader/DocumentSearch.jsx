import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';

import { connect } from 'react-redux';
import { getTextSearch } from './selectors';
import SearchBar from '../components/SearchBar';
import { searchText } from './actions';
import _ from 'lodash';

export class DocumentSearch extends React.PureComponent {
  render() {
    const style = {
      position: 'absolute',
      background: 'white',
      zIndex: '20'
    };

    return <div style={style}>
      <SearchBar
        onChange={this.props.searchText}
      />
      Found {this.props.searchText} on pages: {this.props.textSnippets.pageIds.join(', ')}
    </div>;
  }
}

const mapStateToProps = (state) => {
  console.log('getTextSearch', getTextSearch(state));

  return {
    textSnippets: getTextSearch(state)
  }
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    searchText
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(DocumentSearch);
