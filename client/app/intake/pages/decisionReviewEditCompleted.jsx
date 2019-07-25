import React, { Fragment } from 'react';
import StatusMessage from '../../components/StatusMessage';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS, FORM_TYPES } from '../constants';
import _ from 'lodash';
import Alert from '../../components/Alert';
import IneligibleIssuesList from '../components/IneligibleIssuesList';
import SmallLoader from '../../components/SmallLoader';
import { LOGO_COLORS } from '../../constants/AppConstants';
import COPY from '../../../COPY.json';
import END_PRODUCT_CODES from '../../../constants/END_PRODUCT_CODES.json';

const leadMessageList = ({ veteran, formName, requestIssues, addedIssues }) => {
  const unidentifiedIssues = requestIssues.filter((ri) => ri.isUnidentified);
  const eligibleRequestIssues = requestIssues.filter((ri) => !ri.ineligibleReason);

  const editMessage = () => {
    if (requestIssues.length === 0) {
      return 'removed';
    } else if (_.every(addedIssues, (ri) => ri.withdrawalPending || ri.withdrawalDate)) {
      return 'withdrawn';
    }

    return 'processed';
  };

  const leadMessageArr = [
    `${veteran.name}'s (ID #${veteran.fileNumber}) Request for ${formName} has been ${editMessage()}.`
  ];

  if (eligibleRequestIssues.length !== 0) {
    if (unidentifiedIssues.length > 0) {
      leadMessageArr.push(
        <Alert type="warning">
          <h2>Unidentified issue</h2>
          <p>{COPY.UNIDENTIFIED_ALERT}</p>
          {unidentifiedIssues.map((ri, i) => <p className="cf-red-text" key={`unidentified-alert-${i}`}>
            Unidentified issue: no issue matched for requested "{ri.description}"
          </p>)}
        </Alert>
      );
    } else {
      leadMessageArr.push(
        'If you need to edit this, go to VBMS claim details and click the “Edit in Caseflow” button.'
      );
    }
  }

  leadMessageArr.push(
    <strong>Edit the notice letter to reflect the status of requested issues.</strong>
  );

  return leadMessageArr;
};

const endProductUpdate = (epCode, issues, action) => {
  const epIssues = issues.filter((ri) => ri.endProductCode === epCode);
  const epDescription = END_PRODUCT_CODES[epCode];

  return <Fragment key={`ep-update-${epCode}`}>
    <ul className="cf-success-checklist cf-left-padding">
      <li>
        <strong>A {epDescription} EP is being {action}:</strong>
        { epIssues.map((ri, i) => <p key={`${epCode}-issue-${i}`}>Contention: {ri.contentionText}</p>) }
      </li>
    </ul>
  </Fragment>;
};

class DecisionReviewEditCompletedPage extends React.PureComponent {
  render() {
    const {
      veteran,
      formType,
      beforeIssues,
      afterIssues,
      updatedIssues,
      addedIssues,
      redirectTo
    } = this.props;

    if (!beforeIssues) {
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    }

    if (redirectTo && formType !== FORM_TYPES.APPEAL.key) {
      window.location.href = redirectTo;

      return <SmallLoader message="Loading ..." spinnerColor={LOGO_COLORS.CERTIFICATION.ACCENT} />;
    }

    const selectedForm = _.find(FORM_TYPES, { key: formType });
    const ineligibleRequestIssues = afterIssues.filter((ri) => ri.ineligibleReason);
    const withdrawnRequestIssues = addedIssues.filter((ri) => ri.withdrawalPending);
    const editedRequestIssues = addedIssues.filter((ri) => ri.editedDescription);
    const pageTitle = () => {
      if (afterIssues.length === 0) {
        return 'Review Removed';
      } else if (_.every(addedIssues, (ri) => ri.withdrawalPending || ri.withdrawalDate)) {
        return 'Review Withdrawn';
      }

      return 'Claim Issues Saved';
    };

    const beforeEps = _.uniq(_.map(beforeIssues, 'endProductCode'));
    const afterEps = _.uniq(_.map(afterIssues.filter((ri) => !ri.withdrawalDate), 'endProductCode'));
    const allChangedEps = _.uniq(_.map(updatedIssues, 'endProductCode'));
    const removedEps = _.difference(beforeEps, afterEps);
    const establishedEps = _.difference(allChangedEps, beforeEps);
    const updatedEps = _.difference(allChangedEps, removedEps, establishedEps);

    // render() return:
    return <div>
      <StatusMessage
        title= {pageTitle()}
        type="success"
        leadMessageList={
          leadMessageList({
            veteran,
            formName: selectedForm.name,
            requestIssues: afterIssues,
            addedIssues
          })
        }
        wrapInAppSegment={false}
      />
      { !_.isEmpty(establishedEps) && establishedEps.map((epCode) => {
        return endProductUpdate(epCode, updatedIssues, 'established');
      })}

      { !_.isEmpty(updatedEps) && updatedEps.map((epCode) => {
        const remainingIssues = afterIssues.filter((ri) => !ri.withdrawalDate);

        return endProductUpdate(epCode, remainingIssues, 'updated');
      })}

      { !_.isEmpty(removedEps) && removedEps.map((epCode) => {
        return endProductUpdate(epCode, beforeIssues, 'canceled');
      })}

      { !_.isEmpty(ineligibleRequestIssues) > 0 && <IneligibleIssuesList issues={ineligibleRequestIssues} /> }
      { !_.isEmpty(withdrawnRequestIssues) && <Fragment>
        <ul className="cf-issue-checklist cf-left-padding">
          <li>
            <strong>Withdrawn</strong>
            {withdrawnRequestIssues.map((ri, i) =>
              <p key={`withdrawn-issue-${i}`}>
                {ri.contentionText}
              </p>)}
          </li>
        </ul>
      </Fragment> }
      { !_.isEmpty(editedRequestIssues) && <Fragment>
        <ul className="cf-success-checklist cf-left-padding">
          <li>
            <strong>Edited</strong>
            {editedRequestIssues.map((ri, i) =>
              <p key={`withdrawn-issue-${i}`}>
                {ri.editedDescription}
              </p>)}
          </li>
        </ul>
      </Fragment> }
    </div>
    ;
  }
}

export default connect(
  (state) => ({
    formType: state.formType,
    veteran: state.veteran,
    beforeIssues: state.beforeIssues,
    afterIssues: state.afterIssues,
    updatedIssues: state.updatedIssues,
    addedIssues: state.addedIssues,
    redirectTo: state.redirectTo
  })
)(DecisionReviewEditCompletedPage);
