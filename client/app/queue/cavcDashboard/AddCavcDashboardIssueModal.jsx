/* eslint-disable no-undefined */
import React, { useState } from 'react';
// import { bindActionCreators } from 'redux';
// import { connect, useDispatch } from 'react-redux';
// import { withRouter } from 'react-router';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
// import { requestPatch, showErrorMessage } from '../uiReducer/uiActions';
// import Alert from '../../components/Alert';
// import CAVC_DECISION_TYPES from '../../../constants/CAVC_DECISION_TYPES';
import COPY from '../../../COPY';
import SearchableDropdown from '../../components/SearchableDropdown';
import CAVC_DASHBOARD_DISPOSITIONS from '../../../constants/CAVC_DASHBOARD_DISPOSITIONS';
import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES';
import ISSUE_CATEGORIES from '../../../constants/ISSUE_CATEGORIES';

/**
 * @param {Object} props
 *  - @param {string}   appealId         The id of the appeal we are updating this cavc remand for.
 *  - @param {Object}   error            Error sent from the back end upon submit to be displayed rather than submitting
 *  - @param {boolean}  highlightInvalid Whether or not to show field validation, set to true upon submit
 *  - @param {Object}   history          Provided with react router to be able to route to another page upon success
 */

const AddCavcDashboardIssueModal = ({ closeHandler, submitHandler}) => {

  const [benefitType, setBenefitType] = useState(null);
  const [issueCategory, setIssueCategory] = useState(null);
  const [dispositionByCourt, setDispositionByCourt] = useState(null);
  // const handleCancel = () => onCancel();

  // const [modalIsOpen, setModalIsOpen] = useState(false);

  // const validJudgementDate = () => Boolean(judgementDate) && validateDateNotInFuture(judgementDate);
  // const validMandateDate = () => Boolean(mandateDate) && validateDateNotInFuture(mandateDate);
  // const validInstructions = () => instructions?.length > 0;

  // const validateForm = () => {
  //   return validJudgementDate() && validMandateDate() && validInstructions();
  // };

  // const submit = () => new Promise((resolve) => {
  //   const payload = {
  //     data: {
  //       benefit_type: benefitType,
  //       issue_category: issueCategory,
  //       disposition_by_court: dispositionByCourt,
  //     }
  //   };

  // const successMsgDetail = () => {
  //   if (straightReversalType() || deathDismissalType()) {
  //     return COPY.CAVC_REMAND_READY_FOR_DISTRIBUTION_DETAIL;
  //   }

  //   return COPY.CAVC_REMAND_CREATED_DETAIL;
  // };

  // const successMsg = {
  //   title: COPY.CAVC_REMAND_CREATED_TITLE,
  //   detail: successMsgDetail()
  // };

  //   dispatch(requestPatch(`/appeals/${appealId}/cavc_remand`, payload, successMsg)).
  //     then(() => {
  //       history.replace('/queue');
  //       resolve();
  //     }).
  //     catch((err) => showErrorMessage({ title: 'Error', detail: JSON.parse(err.message).errors[0].detail }));
  // });
  const dispositionsOptions = Object.keys(CAVC_DASHBOARD_DISPOSITIONS).map(
    (value) => ({ value, label: CAVC_DASHBOARD_DISPOSITIONS[value] }));
  const benefitTypeOptions = Object.keys(BENEFIT_TYPES).map(
    (value) => ({ value, label: BENEFIT_TYPES[value] }));
  // const issueCategoryOptions = Object.keys(ISSUE_CATEGORIES.compensation).map(
  //   (value) => ({ value, label: ISSUE_CATEGORIES.compensation[value] }));
  // THIS option was working, but only when cardcoding in the benefittypeoption
  let issueCategoryOptions = [];

  if (benefitType) {
    issueCategoryOptions = Object.keys(ISSUE_CATEGORIES[benefitType.value]).map(
      (value) => ({ value, label: ISSUE_CATEGORIES[benefitType.value][value] }));
  }

  // const selectedBenefitType = benefitTypeOptions.value;
  // const issueCategoryOptions = Object.keys(ISSUE_CATEGORIES.filter(
  //   (category) => category.key === selectedBenefitType)).map(
  //   (value) => ({ value, label: value }));

  // const issueCategoryOptions = Array.keys(ISSUE_CATEGORIES.filter(
  //   (category) => category.key === benefitType)).map(
  //   (value) => ({ value, label: value }));

  // const issueCategoryOptions = Object.keys(ISSUE_CATEGORIES.benefitTypeOptions.value).map(
  //   (value) => ({ value, label: ISSUE_CATEGORIES.benefitTypeOptions.value }));

  // const issueCategoryOptions = Object.keys(ISSUE_CATEGORIES[benefitTypeOptions.value])?.map(
  // (value) => ({ value, label: ISSUE_CATEGORIES[benefitTypeOptions.value] }));

  const benefitTypeField = <SearchableDropdown
    options={benefitTypeOptions}
    label={COPY.CAVC_DASHBOARD_BENEFIT_TYPE_TEXT}
    name="judgement-date"
    value={benefitType}
    onChange={(val) => setBenefitType(val)}
    // onChange={(val) => console.log(val)}
    strongLabel
  />;

  // const outerIssueCategoryOptions = Object.keys(ISSUE_CATEGORIES).map(
  //   (value) => ({ value, label: ISSUE_CATEGORIES[value] }));
  // const issueCategoryOptions = Object.keys(outerIssueCategoryOptions).map(
  //   (value) => ({ value, label: outerIssueCategoryOptions[benefitTypeField.value] }));

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
    // modalIsOpen &&
    <Modal
      title={COPY.ADD_CAVC_DASHBOARD_ISSUE_TEXT}
      // onCancel={handleCancel}
      // onSubmit={handleSubmit}

      // validateForm={validateForm}
      // submit={submit}
      buttons={[
        {
          classNames: ['usa-button', 'cf-btn-link'],
          name: COPY.MODAL_CANCEL_BUTTON,
          onClick: closeHandler,
        },
        {
          classNames: ['usa-button'],
          name: COPY.MODAL_SUBMIT_BUTTON,
          onClick: submitHandler,
        }
      ]}
      closeHandler = {closeHandler}
    >
      {benefitTypeField}
      {issueCategoryField}
      {dispositionByCourtField}
      {/* {error && <Alert title={error.title} type="error">{error.detail}</Alert>} */}
    </Modal>
  );
};

AddCavcDashboardIssueModal.propTypes = {
  // showErrorMessage: PropTypes.func,
  // error: PropTypes.object,
  closeHandler: PropTypes.func,
  submitHandler: PropTypes.func
};

// const mapStateToProps = (state, ownProps) => ({
//   // highlightInvalid: state.ui.highlightFormItems,
//   // error: state.ui.messages.error,
//   // // eslint-disable-next-line camelcase
//   // decisionType: state.queue.appealDetails[ownProps.appealId].cavcRemand?.cavc_decision_type
//   benefitType: state.queue[ownProps].cavcRemand?.cavc_decision_type
// });

// const mapDispatchToProps = (dispatch) => bindActionCreators({
//   requestPatch,
//   showErrorMessage
// }, dispatch);

// export default withRouter(connect(mapStateToProps)(AddCavcDashboardIssueModal));
export default AddCavcDashboardIssueModal;
