import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { reject, first, pick, size, map, find } from 'lodash';

import CannotSaveAlert from '../reader/CannotSaveAlert';
import FuzzySearchableDropdown from '../components/FuzzySearchableDropdown';
import { addNewTag, removeTag } from '../reader/Documents/DocumentsActions';

const fetchSpellingCorrection = (misspelledText) => {
  let fetchData = { queryText: misspelledText };
  const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

  fetch('/fuzzy-search-options',
    {
      body: JSON.stringify(fetchData),
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfToken }
    }).then((response) => response.json()).
    then((data) => {
      console.log('A string');
      console.log(data);
    });
};

class SideBarIssueTags extends PureComponent {
  render() {
    const { doc } = this.props;

    let generateOptionsFromTags = (tags) =>
      map(reject(tags, 'pendingRemoval'), (tag) => ({
        value: tag.text,
        label: tag.text,
        tagId: tag.id
      }));

    let onChange = (values, deletedValue) => {
      console.log(values);
      fetchSpellingCorrection('Doctre');
      if (size(deletedValue)) {
        const tagValue = first(deletedValue).label;
        const result = find(doc.tags, { text: tagValue });

        this.props.removeTag(doc, result);
      } else if (values && values.length) {
        this.props.addNewTag(doc, values);
      }
    };

    let spellingCorrection = (currentTagOptions, correctedTagSpelling) => {
      let tagArr = generateOptionsFromTags(currentTagOptions);
      let correctedTag = {
        value: correctedTagSpelling,
        label: correctedTagSpelling,
        tagId: 14
      };

      tagArr.push(correctedTag);

      return tagArr;
    };

    // fetchSpellingCorrection('Doctre');

    return (
      <div className="cf-issue-tag-sidebar">
        {this.props.error.tag.visible && <CannotSaveAlert />}
        <FuzzySearchableDropdown
          key={doc.id}
          name="tags"
          label="Select or tag issues"
          multi
          dropdownStyling={{ position: 'relative' }}
          creatable
          options={spellingCorrection(this.props.tagOptions, 'Tester')}
          // options={spellingCorrection(this.props.tagOptions, TagController.correct_spelling(this.props.tagOptions))}
          placeholder=""
          value={generateOptionsFromTags(doc.tags)}
          onChange={onChange}
        />
      </div>
    );
  }
}

SideBarIssueTags.propTypes = {
  doc: PropTypes.object,
  removeTag: PropTypes.func,
  addNewTag: PropTypes.func,
  error: PropTypes.object,
  tagOptions: PropTypes.string
};

const mapStateToProps = (state) => {
  return {
    error: state.pdfViewer.pdfSideBarError,
    ...pick(state.pdfViewer, 'tagOptions')
  };
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators(
    {
      addNewTag,
      removeTag
    },
    dispatch
  )
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(SideBarIssueTags);
