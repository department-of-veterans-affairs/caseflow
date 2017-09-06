import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import { clearAllFilters } from './actions';

class HeaderFilterMessage extends React.PureComponent {
  render() {
    const props = this.props;

    // returns the number of truthy values in an object
    const getTruthyCount = (obj) => _(obj).
      values().
      compact().
      size();

    const categoryCount = getTruthyCount(props.docFilterCriteria.category);
    const tagCount = getTruthyCount(props.docFilterCriteria.tag);

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

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearAllFilters
}, dispatch);

HeaderFilterMessage.propTypes = {
  docFilterCriteria: PropTypes.object,
  clearAllFilters: PropTypes.func.isRequired
};

const mapStateToProps = (state) => ({
  viewingDocumentsOrComments: state.readerReducer.viewingDocumentsOrComments
});

export default connect(mapStateToProps, mapDispatchToProps)(HeaderFilterMessage);
