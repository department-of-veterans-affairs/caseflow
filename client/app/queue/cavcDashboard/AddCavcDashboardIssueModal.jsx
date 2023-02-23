/* eslint-disable no-undefined */
import React, { useState } from 'react';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
import COPY from '../../../COPY';
import SearchableDropdown from '../../components/SearchableDropdown';
import CAVC_DASHBOARD_DISPOSITIONS from '../../../constants/CAVC_DASHBOARD_DISPOSITIONS';
import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES';
import ISSUE_CATEGORIES from '../../../constants/ISSUE_CATEGORIES';

const AddCavcDashboardIssueModal = ({ closeHandler, submitHandler }) => {

  const [benefitType, setBenefitType] = useState(null);
  const [issueCategory, setIssueCategory] = useState(null);
  const [dispositionByCourt, setDispositionByCourt] = useState(null);
  const issue = {
    benefit_type: benefitType?.value,
    issue_category: issueCategory,
    disposition: dispositionByCourt?.label
  };

  const submitIssue = () => {
    submitHandler(issue);
  };

  const dispositionsOptions = Object.keys(CAVC_DASHBOARD_DISPOSITIONS).map(
    (value) => ({ value, label: CAVC_DASHBOARD_DISPOSITIONS[value] }));
  const benefitTypeOptions = Object.keys(BENEFIT_TYPES).map(
    (value) => ({ value, label: BENEFIT_TYPES[value] }));

  let issueCategoryOptions = [];

  if (benefitType) {
    issueCategoryOptions = Object.keys(ISSUE_CATEGORIES[benefitType.value]).map(
      (value) => ({ value, label: ISSUE_CATEGORIES[benefitType.value][value] }));
  }

  const benefitTypeField = <SearchableDropdown
    options={benefitTypeOptions}
    label={COPY.CAVC_DASHBOARD_BENEFIT_TYPE_TEXT}
    name="judgement-date"
    value={benefitType}
    onChange={(val) => setBenefitType(val)}
    strongLabel
  />;

  const issueCategoryField = <SearchableDropdown
    options={issueCategoryOptions}
    label={COPY.CAVC_DASHBOARD_ISSUE_CATEGORY_TEXT}
    name="mandate-date"
    value={issueCategory}
    onChange={(val) => setIssueCategory(val)}
    strongLabel
  />;

  const dispositionByCourtField = <SearchableDropdown
    options={dispositionsOptions}
    label={COPY.CAVC_DASHBOARD_DISPOSITION_BY_COURT_TEXT}
    name="context-and-instructions-textBox"
    value={dispositionByCourt}
    onChange={(val) => setDispositionByCourt(val)}
    strongLabel
  />;

  return (
    <Modal
      title={COPY.ADD_CAVC_DASHBOARD_ISSUE_TEXT}
      buttons={[
        {
          classNames: ['usa-button', 'cf-btn-link'],
          name: COPY.MODAL_CANCEL_BUTTON,
          onClick: closeHandler,
        },
        {
          classNames: ['usa-button'],
          name: COPY.MODAL_SUBMIT_BUTTON,
          disabled: (!benefitType || !issueCategory || !dispositionByCourt),
          onClick: submitIssue,
        }
      ]}
      closeHandler = {closeHandler}
    >
      {benefitTypeField}
      {issueCategoryField}
      {dispositionByCourtField}
    </Modal>
  );
};

AddCavcDashboardIssueModal.propTypes = {
  closeHandler: PropTypes.func,
  submitHandler: PropTypes.func
};

export default AddCavcDashboardIssueModal;
