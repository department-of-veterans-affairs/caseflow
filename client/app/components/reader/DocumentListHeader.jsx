import React from 'react';
import PropTypes from 'prop-types';
import SearchBar from '../SearchBar';
import Alert from '../Alert';
import { connect } from 'react-redux';
import { setSearch, clearAllFilters, clearSearch } from '../../reader/actions';
import _ from 'lodash';
import Analytics from '../../util/AnalyticsUtil';
import ApiUtil from '../../util/ApiUtil';
import DocumentsCommentsButton from '../../reader/DocumentsCommentsButton';

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

    const categoryFilters = Object.keys(props.docFilterCriteria.category).some((category) =>
      props.docFilterCriteria.category[category]
    );
    const tagFilters = Object.keys(props.docFilterCriteria.tag).some((tag) =>
      props.docFilterCriteria.tag[tag]
    );
    const filteredCategories = [].concat(
      categoryFilters ? ['categories'] : [],
      tagFilters ? ['tags'] : []).join(' ');

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
      {Boolean(filteredCategories.length) &&
        <Alert
          title="Showing limited results"
          type="info">
          Documents are currently
            filtered by {filteredCategories}. <a
              href="#"
              id="clear-filters"
              onClick={props.clearAllFilters}>
            Click here to see all documents.</a>
        </Alert>}
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
  vacolsId: state.loadedAppealId
});

const mapDispatchToProps = (dispatch) => ({
  clearAllFilters: () => {
    Analytics.event('Claims Folder', 'click', 'Clear all filters');
    dispatch(clearAllFilters());
  },
  clearSearch: () => {
    dispatch(clearSearch());
  },
  setSearch: (searchQuery) => {
    dispatch(setSearch(searchQuery));
  }
});

export default connect(mapStateToProps, mapDispatchToProps)(DocumentListHeader);
