import React, { PureComponent } from 'react';
import { bindActionCreators } from 'redux';
import CannotSaveAlert from '../reader/CannotSaveAlert';
import { connect } from 'react-redux';
import SearchableDropdown from '../components/SearchableDropdown';
import _ from 'lodash';

import { addNewTag, removeTag } from '../reader/actions';

class SideBarIssueTags extends PureComponent {
  render() {
    const {
      doc
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

        this.props.removeTag(doc, result.id);
      } else if (values && values.length) {
        this.props.addNewTag(doc, values);
      }
    };

    return <div className="cf-issue-tag-sidebar">
      {this.props.showErrorMessage.tag && <CannotSaveAlert />}
      <SearchableDropdown
        key={doc.id}
        name="tags"
        label="Select or tag issue(s)"
        multi={true}
        creatable={true}
        options={generateOptionsFromTags(this.props.tagOptions)}
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
    ..._.pick(state.readerReducer.ui, 'tagOptions')
  };
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    addNewTag,
    removeTag
  }, dispatch)
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(SideBarIssueTags);
