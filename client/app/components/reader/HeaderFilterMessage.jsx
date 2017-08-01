import React from 'react';
import PropTypes from 'prop-types';
import Analytics from '../../util/AnalyticsUtil';
import { clearAllFilters } from '../../reader/actions';
import { connect } from 'react-redux';
import _ from 'lodash';

class HeaderFilterMessage extends React.PureComponent {
  render() {
    const props = this.props;

    const categoryCount = _(props.docFilterCriteria.category).
      values().
      compact().
      size();
    const tagCount = _.size(props.docFilterCriteria.tag);

    const filteredCategories = _.compact([
      categoryCount && `Categories (${categoryCount})`,
      tagCount && `Issue tags (${tagCount})`,
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

const mapDispatchToProps = (dispatch) => ({
  clearAllFilters: () => {
    Analytics.event('Claims Folder', 'click', 'Clear all filters');
    dispatch(clearAllFilters());
  }
});

HeaderFilterMessage.propTypes = {
  docFilterCriteria: PropTypes.object,
  clearAllFilters: PropTypes.func.isRequired
};

const mapStateToProps = (state) => ({
  viewingDocumentsOrComments: state.viewingDocumentsOrComments
});

export default connect(mapStateToProps, mapDispatchToProps)(HeaderFilterMessage);