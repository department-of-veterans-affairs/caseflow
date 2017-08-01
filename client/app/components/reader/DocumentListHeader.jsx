import React from 'react';
import PropTypes from 'prop-types';
import SearchBar from '../SearchBar';
import { connect } from 'react-redux';
import { setSearch, clearSearch } from '../../reader/actions';
import _ from 'lodash';
import ApiUtil from '../../util/ApiUtil';
import DocumentsCommentsButton from '../../reader/DocumentsCommentsButton';
import HeaderFilterMessage from './HeaderFilterMessage';

class DocumentListHeader extends React.Component {
  // Record the search value for analytics purposes, don't worry if it fails.
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
        <div className="search-bar-and-doc-count">
          <SearchBar
            id="searchBar"
            onChange={props.setSearch}
            onClearSearch={props.clearSearch}
            onClick={props.clickSearch}
            recordSearch={this.recordSearch}
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
  numberOfDocuments: state.ui.filteredDocIds ? state.ui.filteredDocIds.length : _.size(state.documents),
  docFilterCriteria: state.ui.docFilterCriteria,
  vacolsId: state.loadedAppealId,
});

const mapDispatchToProps = (dispatch) => ({
  clearSearch: () => {
    dispatch(clearSearch());
  },
  setSearch: (searchQuery) => {
    dispatch(setSearch(searchQuery));
  }
});

export default connect(mapStateToProps, mapDispatchToProps)(DocumentListHeader);
