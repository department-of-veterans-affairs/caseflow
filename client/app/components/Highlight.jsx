import React, { PureComponent } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import Highlighter from 'react-highlight-words';
import _ from 'lodash';

class Highlight extends PureComponent {
  render() {
    const { searchQuery } = this.props;

    return <span>
      <Highlighter
        searchWords={_.union([searchQuery], searchQuery.split(' '))}
        textToHighlight={this.props.children}
      />
    </span>;
  }
}

Highlight.propTypes = {
  searchQuery: PropTypes.string.isRequired,
  children: PropTypes.string.isRequired
};

Highlight.defaultProps = {
  searchQuery: '',
  children: ''
};

const mapStateToProps = (state) => ({
  searchQuery: state.readerReducer.ui.docFilterCriteria.searchQuery
});

export default connect(
  mapStateToProps
)(Highlight);
