import React from 'react';
import PropTypes from 'prop-types';
import SearchBar from '../SearchBar';
import { connect } from 'react-redux';
import { setSearch, clearAllFilters, clearSearch } from '../../reader/actions';
import _ from 'lodash';
import Analytics from '../../util/AnalyticsUtil';
import ApiUtil from '../../util/ApiUtil';
import DocumentsCommentsButton from '../../reader/DocumentsCommentsButton';


const HeaderFilterMessage = (props) => {

  const categoryFilters = Object.keys(props.docFilterCriteria.category).some((category) =>
    props.docFilterCriteria.category[category]
  );
  const tagFilters = Object.keys(props.docFilterCriteria.tag).some((tag) =>
    props.docFilterCriteria.tag[tag]
  );

  const categoryCount = _.values(props.docFilterCriteria.category).reduce((numberOfCategories, categoryShown) => {
    return categoryShown ? numberOfCategories + 1 : numberOfCategories;
  }, 0);
  const tagCount = _.values(props.docFilterCriteria.tag).length;

  const filteredCategories = [].concat(
    categoryFilters ? [`Categories (${categoryCount})`] : [],
    tagFilters ? [`Issue tags (${tagCount})`] : [],
    props.viewingDocumentsOrComments === 'comments' ? ['Comments'] : []).
    join(', ');

  if (!filteredCategories.length) {
    return null;
  }

  return <p className="document-list-filter-message">Filtering by: {filteredCategories}. <a
    href="#"
    id="clear-filters"
    onClick={props.clearAllFilters}>
    Clear all filters.</a></p>;
};

const headerFilterMessageMapDispatchToProps = (dispatch) => ({
  clearAllFilters: () => {
    Analytics.event('Claims Folder', 'click', 'Clear all filters');
    dispatch(clearAllFilters());
  }
});

const headerFilterMessageMapStateToProps = (state) => ({
  viewingDocumentsOrComments: state.viewingDocumentsOrComments
});

const ConnectedHeaderFilterMessage = connect(headerFilterMessageMapStateToProps,
                                             headerFilterMessageMapDispatchToProps)(HeaderFilterMessage);

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
        <ConnectedHeaderFilterMessage docFilterCriteria={props.docFilterCriteria} />
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
  vacolsId: state.loadedAppealId,
  docFilterCriteria: state.ui.docFilterCriteria
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
