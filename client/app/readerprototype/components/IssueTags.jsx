import PropTypes from 'prop-types';
import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import SearchableDropdown from '../../components/SearchableDropdown';
import CannotSaveAlert from '../../reader/CannotSaveAlert';
import { addNewTag, removeTag } from '../../reader/Documents/DocumentsActions';
import { tagErrorSelector, tagSelector } from '../selectors';

const tagsToOptions = (tags) =>
  tags.
    filter((tag) => !tag.pendingRemoval).
    map((tag) => ({
      value: tag.text,
      label: tag.text,
      tagId: tag.id,
    }));

const IssueTags = ({ doc }) => {
  const availableTags = useSelector(tagSelector);
  const errors = useSelector(tagErrorSelector);
  const dispatch = useDispatch();
  const assignedTagOptions = tagsToOptions(doc.tags);
  const availableTagOptions = tagsToOptions(availableTags);

  const onChange = (values, tagsRemoved) => {
    if (tagsRemoved) {
      dispatch(removeTag(doc, tagsRemoved[0]));
    } else if (values?.length) {
      dispatch(addNewTag(doc, values));
    }
  };

  return (
    <div className="cf-issue-tag-sidebar">
      {errors?.visible && <CannotSaveAlert />}
      <SearchableDropdown
        key={doc.id}
        name="tags"
        label="Select or tag issues"
        multi
        dropdownStyling={{ position: 'relative' }}
        creatable
        options={availableTagOptions}
        placeholder=""
        value={assignedTagOptions}
        onChange={onChange}
      />
    </div>
  );
};

IssueTags.propTypes = {
  doc: PropTypes.object,
};

export default IssueTags;
