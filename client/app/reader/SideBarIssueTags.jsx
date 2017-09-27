import React, { PureComponent } from 'react';
import CannotSaveAlert from '../reader/CannotSaveAlert';
import { connect } from 'react-redux';
import SearchableDropdown from '../components/SearchableDropdown';
import _ from 'lodash';

class SideBarIssueTags extends PureComponent {
  render() {
    const {
      doc,
      tagOptions,
      showErrorMessage,
      removeTag,
      addNewTag
    } = this.props;

    let generateOptionsFromTags = (tags) =>
      _(tags).
        reject('pendingRemoval').
        map((tag) => ({
          value: tag.text,
          label: tag.text,
          tagId: tag.id })
        ).
        value();

    let onChange = (values, deletedValue) => {
      if (_.size(deletedValue)) {
        const tagValue = _.first(deletedValue).label;
        const result = _.find(doc.tags, { text: tagValue });

        removeTag(doc, result.id);
      } else if (values && values.length) {
        addNewTag(doc, values);
      }
    };

    return <div className="cf-issue-tag-sidebar">
      {showErrorMessage.tag && <CannotSaveAlert />}
      <SearchableDropdown
        key={doc.id}
        name="tags"
        label="Select or tag issue(s)"
        multi={true}
        creatable={true}
        options={generateOptionsFromTags(tagOptions)}
        placeholder=""
        value={generateOptionsFromTags(doc.tags)}
        onChange={onChange}
        selfManageValueState={true}
      />
    </div>;
  }
}

const mapStateToProps = (state) => {
  return {
    showErrorMessage: state.readerReducer.ui.pdfSidebar.showErrorMessage,
    tagOptions: state.readerReducer.ui.tagOptions
  };
};

export default connect(
  mapStateToProps
)(SideBarIssueTags);
