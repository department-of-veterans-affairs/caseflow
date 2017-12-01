import React, { PureComponent } from 'react';
<<<<<<< HEAD
import CannotSaveAlert from '../reader/CannotSaveAlert';
import { connect } from 'react-redux';
import SearchableDropdown from '../components/SearchableDropdown';
import _ from 'lodash';

class SideBarIssueTags extends PureComponent {
  render() {
    const {
      doc,
      tagOptions,
      removeTag,
      addNewTag
=======
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';

import CannotSaveAlert from '../reader/CannotSaveAlert';
import SearchableDropdown from '../components/SearchableDropdown';
import { addNewTag, removeTag } from '../reader/PdfViewer/PdfViewerActions';

class SideBarIssueTags extends PureComponent {
  render() {
    const {
      doc
>>>>>>> 06be805a17ef706c294f809fac882ebfe6c82a5b
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

<<<<<<< HEAD
        removeTag(doc, result.id);
      } else if (values && values.length) {
        addNewTag(doc, values);
=======
        this.props.removeTag(doc, result.id);
      } else if (values && values.length) {
        this.props.addNewTag(doc, values);
>>>>>>> 06be805a17ef706c294f809fac882ebfe6c82a5b
      }
    };

    return <div className="cf-issue-tag-sidebar">
<<<<<<< HEAD
      {this.props.showErrorMessage.tag && <CannotSaveAlert />}
=======
      {this.props.error.tag.visible && <CannotSaveAlert />}
>>>>>>> 06be805a17ef706c294f809fac882ebfe6c82a5b
      <SearchableDropdown
        key={doc.id}
        name="tags"
        label="Select or tag issue(s)"
<<<<<<< HEAD
        multi={true}
        creatable={true}
        options={generateOptionsFromTags(tagOptions)}
        placeholder=""
        value={generateOptionsFromTags(doc.tags)}
        onChange={onChange}
        selfManageValueState={true}
=======
        multi
        creatable
        options={generateOptionsFromTags(this.props.tagOptions)}
        placeholder=""
        value={generateOptionsFromTags(doc.tags)}
        onChange={onChange}
        selfManageValueState
>>>>>>> 06be805a17ef706c294f809fac882ebfe6c82a5b
      />
    </div>;
  }
}

const mapStateToProps = (state) => {
  return {
<<<<<<< HEAD
    showErrorMessage: state.readerReducer.ui.pdfSidebar.showErrorMessage
  };
};

export default connect(
  mapStateToProps
=======
    error: state.readerReducer.ui.pdfSidebar.error,
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
>>>>>>> 06be805a17ef706c294f809fac882ebfe6c82a5b
)(SideBarIssueTags);
