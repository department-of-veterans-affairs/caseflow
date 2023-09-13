import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { reject, first, pick, size, map, find } from 'lodash';

import CannotSaveAlert from '../reader/CannotSaveAlert';
import SearchableDropdown from '../components/SearchableDropdown';
import { addNewTag, removeTag, generateTags } from '../reader/Documents/DocumentsActions';
import Button from '../components/Button';
import Alert from '../components/Alert';

class SideBarIssueTags extends PureComponent {
  render() {
    const { doc, featureToggles } = this.props;
    const { auto_tagged, isAutoTagPending } = doc
    const isVisible = featureToggles.auto_tagging_ability && featureToggles.can_manually_auto_tag && !auto_tagged

    let generateOptionsFromTags = (tags) =>
      map(reject(tags, 'pendingRemoval'), (tag) => ({
        value: tag.text,
        label: tag.text,
        tagId: tag.id
      }));

    let onChange = (values, deletedValue) => {
      if (size(deletedValue)) {
        const tagValue = first(deletedValue).label;
        const result = find(doc.tags, { text: tagValue });

        this.props.removeTag(doc, result);
      } else if (values && values.length) {
        this.props.addNewTag(doc, values);
      }
    };

    return (
      <div className="cf-issue-tag-sidebar">
        {isAutoTagPending && <Alert type="info" message="Auto-tags generating. Please wait a moment." />}
        {this.props.error.tag.visible && <CannotSaveAlert />}
        {isVisible && <span className="cf-right-side cf-generate-tag-button">
          <Button onClick={() => this.props.generateTags(doc)} role="button" disabled={auto_tagged || isAutoTagPending}>Generate auto-tags</Button>
        </span>}
        <SearchableDropdown
          key={doc.id}
          name="tags"
          label="Select or tag issues"
          multi
          dropdownStyling={{ position: 'relative' }}
          creatable
          options={generateOptionsFromTags(this.props.tagOptions)}
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
  generateTags: PropTypes.func,
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
      removeTag,
      generateTags,
    },
    dispatch
  )
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(SideBarIssueTags);
