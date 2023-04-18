import React from 'react';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import AddedIssue from '../../intake/components/IssueList';
import TextField from '../../components/TextField';
import {
  INTAKE_EDIT_ISSUE_TITLE,
  INTAKE_EDIT_ISSUE_SELECT_SPECIAL_ISSUES,
  INTAKE_EDIT_ISSUE_CHANGE_MESSAGE
} from 'app/../COPY';

export const EditIntakeIssuesModal = (props) => {

  return (
    <div>
      <p>I love dinosaurs.</p>
      {console.log(`props print here: ${JSON.stringify(props)}`)}
    </div>
  );
};

EditIntakeIssuesModal.propTypes = {
};

export default EditIntakeIssuesModal;
