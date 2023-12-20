import React from 'react';
import PropTypes from 'prop-types';
import Highlighter from 'react-highlight-words';
import { union } from 'lodash';

export const Highlight = ({ searchQuery, children }) => (
  <span>
    <Highlighter
      searchWords={union([searchQuery], searchQuery.split(' '))}
      textToHighlight={children}
      autoEscape
    />
  </span>
);

Highlight.propTypes = {
  searchQuery: PropTypes.string.isRequired,
  children: PropTypes.string.isRequired
};

Highlight.defaultProps = {
  searchQuery: '',
  children: ''
};
