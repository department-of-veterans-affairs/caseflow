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

class HeaderFilterMessage extends React.PureComponent {
  render() {
    const props = this.props;

    const categoryFilters = Object.keys(props.docFilterCriteria.category).some((category) =>
      props.docFilterCriteria.category[category]
    );
    const tagFilters = Object.keys(props.docFilterCriteria.tag).some((tag) =>
      props.docFilterCriteria.tag[tag]
    );

    const categoryCount = _(props.docFilterCriteria.category).
      values().
      compact().
      size();
    const tagCount = _.size(props.docFilterCriteria.tag);

    const filteredCategories = _.compact([
      categoryFilters && `Categories (${categoryCount})`,
      tagFilters && `Issue tags (${tagCount})`,
      props.viewingDocumentsOrComments === 'comments' && 'Comments'
    ]).join(', ');

    if (!filteredCategories.length) {
      return null;
    }

    return <p className="document-list-filter-message">Filtering by: {filteredCategories}. <a
      href="#"
      id="clear-filters"
      onClick={props.clearAllFilters}>
      Clear all filters.</a></p>;
  }
}

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
        <div className="search-bar-and-doc-count">
          <SearchBar
            id="searchBar"
            onChange={props.setSearch}
            onClearSearch={props.clearSearch}
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
  vacolsId: state.loadedAppealId,
  docFilterCriteria: state.ui.docFilterCriteria
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    setSearch,
    clearSearch,
    clearAllFilters
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(DocumentListHeader);
