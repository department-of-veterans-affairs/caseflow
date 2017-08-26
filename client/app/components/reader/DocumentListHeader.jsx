import React from 'react';
import PropTypes from 'prop-types';
import SearchBar from '../SearchBar';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { setSearch, clearSearch, clearAllFilters } from '../../reader/actions';
import _ from 'lodash';
import ApiUtil from '../../util/ApiUtil';
import DocumentsCommentsButton from '../../reader/DocumentsCommentsButton';
import HeaderFilterMessage from './HeaderFilterMessage';

class DocumentListHeader extends React.Component {
  // Record the search value for analytics purposes. Don't worry if it fails.
  recordSearch = (query) => {
    ApiUtil.post(
      `/reader/appeal/${this.props.vacolsId}/claims_folder_searches`,
      { data: { query } }
    ).then(_.noop);
  }

  render() {
    const props = this.props;

    return <div>
      <div className="document-list-header">
        <div className="search-bar-and-doc-count cf-search-ahead-parent">
          <SearchBar
            id="searchBar"
            onChange={props.setSearch}
            onClearSearch={props.clearSearch}
            recordSearch={this.recordSearch}
            isSearchAhead={true}
            placeholder="Type to search..."
            value={props.docFilterCriteria.searchQuery}
            size="small"
            analyticsCategory="Claims Folder"
          />
          <div className="num-of-documents">
            {props.numberOfDocuments} Documents
          </div>
        </div>
        <DocumentsCommentsButton />
      </div>
        <HeaderFilterMessage docFilterCriteria={props.docFilterCriteria} />
    </div>;
  }
}

DocumentListHeader.propTypes = {
  setSearch: PropTypes.func.isRequired,
  noDocuments: PropTypes.bool,
  clearAllFilters: PropTypes.func,
  numberOfDocuments: PropTypes.number.isRequired,
  vacolsId: PropTypes.string
};

const mapStateToProps = (state) => ({
  numberOfDocuments: state.readerReducer.ui.filteredDocIds ?
    state.readerReducer.ui.filteredDocIds.length : _.size(state.readerReducer.documents),
  docFilterCriteria: state.readerReducer.ui.docFilterCriteria,
  vacolsId: state.readerReducer.loadedAppealId
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    setSearch,
    clearSearch,
    clearAllFilters
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(DocumentListHeader);
