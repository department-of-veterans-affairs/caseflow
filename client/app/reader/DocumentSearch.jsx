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
      top: '0',
      bottom: '0',
      zIndex: '20'
    };

    const textDivs = this.props.searchObjects.map((obj) => <p>{obj.before}[{this.props.searchTextValue}]{obj.after}</p>);

    return <div style={style}>
      <SearchBar
        onChange={this.props.searchText}
      />
      {textDivs}
    </div>;
  }
}

const mapStateToProps = (state) => {
  const { pageIds, pagesText, searchText } = getTextSearch(state);
  console.log('getTextSearch', getTextSearch(state));
  // if (!_.isEmpty(pagesText)) {
  //   debugger;
  // }
  const scopedPages = pageIds.map((id) => pagesText[id]);
  const searchObjects = scopedPages.map((text) => {
    const split = text.text.split(searchText);

    return _.range(split.length - 1).map((index) => {
      return {
        before: split[index].substring(split[index].length - 10),
        after: split[index + 1].substring(0, 10)
      };
    });
  }).reduce((acc, obj) => acc.concat(obj), []);

  return {
    searchObjects,
    searchTextValue: searchText,
    textSnippets: getTextSearch(state),
    documentSearchString: state.readerReducer.documentSearchString
  }
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    searchText
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(DocumentSearch);
