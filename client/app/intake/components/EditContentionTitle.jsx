import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import TextareaField from '../../components/TextareaField';
import Button from '../../components/Button';
import { css } from 'glamor';
import { setEditContentionText } from '../actions/addIssues';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

export const EditContentionTitle = ({
  issue,
  issueIdx,
  setEditContentionText: callback,
  disableEditingForCompAndPen,
}) => {
  const { text, editedDescription, notes } = issue;
  const [editing, setEditing] = useState(false);
  const [value, setValue] = useState(editedDescription ?? text);

  const toggleEdit = () => setEditing(!editing);

  const handleChange = (val) => setValue(val);

  const handleSubmit = () => {
    callback(issueIdx, value);
    setEditing(false);
  };

  // Ensure that we update our state in case our inputs have changed
  useEffect(() => setValue(editedDescription ?? text), [issue]);

  const label = `${issueIdx + 1}. Contention title`;

  return (
    <div>
      {!editing && (
        <div className="issue-edit-text">
          <Button
            onClick={toggleEdit}
            classNames={['cf-btn-link', 'edit-contention-issue']}
            disabled={disableEditingForCompAndPen}
          >
            {COPY.INTAKE_EDIT_TITLE}
          </Button>
        </div>
      )}

      {editing && (
        <div className="issue-text-style">
          <TextareaField
            name={label}
            label={label}
            placeholder={editedDescription ?? text}
            onChange={handleChange}
            value={value}
            strongLabel
          />
          <p>{editedDescription ?? text}</p>
          {notes && (
            <p
              {...css({
                fontStyle: 'italic',
              })}
            >
              Notes: {notes}
            </p>
          )}
          <div className="issue-text-buttons">
            {editing && (
              <Button classNames={['cf-btn-link']} onClick={toggleEdit}>
                Cancel
              </Button>
            )}
            <Button
              name="submit-issue"
              classNames={['cf-submit', 'issue-edit-submit-button']}
              disabled={!value}
              onClick={handleSubmit}
            >
              Submit
            </Button>
          </div>
        </div>
      )}
    </div>
  );
};

EditContentionTitle.propTypes = {

  /**
   * Request issue; proptypes here are minimal subset
   */
  issue: PropTypes.shape({
    editedDescription: PropTypes.string,
    index: PropTypes.number,
    notes: PropTypes.string,
    text: PropTypes.string,
  }),

  /**
   * Number (should match `issue.index`)
   */
  issueIdx: PropTypes.number,

  /**
   * Callback with two arguments: issue index and new value
   */
  setEditContentionText: PropTypes.func,
  disableEditingForCompAndPen: PropTypes.bool,
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      setEditContentionText,
    },
    dispatch
  );

export default connect(
  null,
  mapDispatchToProps
)(EditContentionTitle);
