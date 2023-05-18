import React, { useState } from 'react';
import { css } from 'glamor';

import { LABELS } from './cavcDashboardConstants';
import PropTypes from 'prop-types';
import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES';
import COPY from '../../../COPY';
import SearchableDropdown from '../../components/SearchableDropdown';
import CavcDecisionReasons from './CavcDecisionReasons';
import Button from '../../components/Button';
import CAVC_DASHBOARD_DISPOSITIONS from '../../../constants/CAVC_DASHBOARD_DISPOSITIONS';
import RemoveCavcDashboardIssueModal from './RemoveCavcDashboardIssueModal';
import { useDispatch, useSelector } from 'react-redux';
import { removeCheckedDecisionReason, setDispositionValue } from './cavcDashboardActions';

const singleIssueStyling = (userCanEdit) => {
  const style = {
    marginBottom: '1.5em !important',
    display: 'grid',
    fontWeight: 'normal',
    gridTemplateColumns: '70% 30%',
    '@media(max-width: 1200px)': { width: '100%' },
    '@media(max-width: 829px)': {
      display: 'flex',
      flexDirection: 'column',
    }
  };

  if (!userCanEdit) {
    style['@media(max-width: 829px)'].flexDirection = 'row';
  }

  return css(style);
};

const issueColumnStyling = (userCanEdit) => {
  if (userCanEdit) {
    return css({});
  }

  return css({
    '@media(max-width: 829px)': {
      width: '70%'
    }
  });
};

const dispositionColumnStyling = (userCanEdit) => {
  if (userCanEdit) {
    return css({});
  }

  return css({
    '@media(max-width: 829px)': {
      width: '30%'
    }
  });
};

const headerStyling = css({
  display: 'grid',
  gridTemplateColumns: '70% 30%',
  marginBottom: '0',
});

const issueSectionStyling = css({
  marginTop: '1.5em'
});

const olStyling = css({
  fontWeight: 'bold',
  paddingLeft: '1em'
});

const issueDescriptionStyling = css({
  overflowWrap: 'anywhere',
});

const CavcDashboardIssue = (props) => {
  const {
    issue,
    index,
    dispositions,
    removeIssueHandler,
    addedIssueSection,
    dashboardIndex,
    userCanEdit
  } = props;

  const [removeModalIsOpen, setRemoveModalIsOpen] = useState(false);
  const selectionBases = useSelector((state) => state.cavcDashboard.selection_bases);

  const disposition = dispositions?.find(
    (dis) => dis.request_issue_id === issue.id ||
    dis.cavc_dashboard_issue_id === issue.id)?.disposition;

  const dispositionIssueType = dispositions?.find(
    (dis) => dis.request_issue_id === issue.id ||
      /* eslint-disable-next-line camelcase */
      dis.cavc_dashboard_issue_id === issue.id)?.request_issue_id ? 'request_issue' : 'cavc_dashboard_issue';

  const loadCheckedBoxes = dispositions.find(
    (dis) => dis.request_issue_id === issue.id ||
    /* eslint-disable-next-line camelcase */
    dis.cavc_dashboard_issue_id === issue.id)?.cavc_dispositions_to_reasons;

  const dispositionsOptions = Object.keys(CAVC_DASHBOARD_DISPOSITIONS).map(
    (value) => ({ value, label: CAVC_DASHBOARD_DISPOSITIONS[value] }));

  const dispositionsRequiringReasons =
    [CAVC_DASHBOARD_DISPOSITIONS.reversed, CAVC_DASHBOARD_DISPOSITIONS.vacated_and_remanded];

  let issueType = {};
  const dispatch = useDispatch();

  const requireDecisionReason = () => {
    /* eslint-disable-next-line */
    if (dispositionsRequiringReasons.includes(disposition)) {
      return true;
    }
    dispatch(removeCheckedDecisionReason(issue.id));

    return false;
  };

  if (addedIssueSection) {
    issueType = issue.issue_category;
  } else {
    issueType = issue.description;
  }

  const toggleRemoveIssueModal = () => {
    setRemoveModalIsOpen(!removeModalIsOpen);
  };

  const removeIssue = () => {
    removeIssueHandler(index, issue);
    toggleRemoveIssueModal();
  };

  const setDispositionOption = (option) => {
    const dispositionIssueId =
      dispositions[0].cavc_dashboard_issue_id || dispositions[0].request_issue_id;

    dispatch(setDispositionValue(dashboardIndex, dispositionIssueId, option));
  };

  const renderDispositionDropdown = () => {
    if (userCanEdit) {
      return (
        <SearchableDropdown
          name={`issue-dispositions-${index}`}
          label="Dispositions"
          placeholder={disposition}
          defaultValue={disposition}
          searchable
          hideLabel
          options={dispositionsOptions}
          onChange={(option) => setDispositionOption(option.label)}
        />
      );
    }

    return (
      <div>
        <label>{disposition}</label>
      </div>
    );
  };

  return (
    <li key={index} className="dash-li">
      <div {...singleIssueStyling(userCanEdit)}>
        <div {...issueColumnStyling(userCanEdit)}>
          <div>
            <strong> Benefit type: </strong> {BENEFIT_TYPES[issue.benefit_type]}
          </div>
          <div>
            <strong>Issue: </strong>
            {issueType}
            {issue.issue_description &&
              <span {...issueDescriptionStyling}> - {issue.issue_description}</span>}
          </div>
        </div>
        <div {...dispositionColumnStyling(userCanEdit)}>
          {renderDispositionDropdown()}
        </div>
        <div />
      </div>
      {requireDecisionReason() && selectionBases.length > 0 &&
        <CavcDecisionReasons
          uniqueId={issue.id}
          initialDispositionRequiresReasons={dispositionsRequiringReasons.includes(disposition)}
          dispositionIssueType={dispositionIssueType}
          loadCheckedBoxes={loadCheckedBoxes}
          userCanEdit={userCanEdit}
        />
      }
      {addedIssueSection && userCanEdit &&
        <>
          <Button
            type="button"
            name="Remove Issue Button"
            classNames={['cf-btn-link', 'dash-button-remove']}
            onClick={toggleRemoveIssueModal}
          >
            <i className="fa fa-trash-o" aria-hidden="true"></i>  { COPY.REMOVE_CAVC_DASHBOARD_ISSUE_BUTTON_TEXT }
          </Button>
          {removeModalIsOpen &&
            <RemoveCavcDashboardIssueModal closeHandler={toggleRemoveIssueModal} submitHandler={removeIssue} />
          }
        </>
      }
    </li>
  );
};

const CavcDashboardIssuesSection = (props) => {
  const { dashboard, dashboardIndex, removeDashboardIssue, userCanEdit } = props;
  const issues = dashboard.remand_request_issues;
  const cavcIssues = dashboard.cavc_dashboard_issues;
  const dashboardDispositions = dashboard.cavc_dashboard_dispositions;
  const dashboardId = dashboard.id;

  // the handler is in this component because it needs the dashboardIndex prop that isn't passed down
  const removeIssueHandler = (issueIndex, issue) => {
    removeDashboardIssue(dashboardIndex, issue);
  };

  return (
    <div {...issueSectionStyling}>
      <div>
        <strong {...headerStyling}>
          <span>{LABELS.CAVC_DASHBOARD_ISSUES}</span>
          <span>{LABELS.CAVC_DASHBOARD_DISPOSITIONS}</span>
        </strong>
        <hr />
      </div>
      <ol {...olStyling}>
        {issues?.map((issue, i) => {
          const issueDisposition = dashboardDispositions.filter((dis) => {
            return dis.request_issue_id === issue.id;
          });

          return (
            <React.Fragment key={i}>
              <CavcDashboardIssue
                issue={issue}
                index={i}
                dispositions={issueDisposition}
                dashboardId={dashboardId}
                userCanEdit={userCanEdit}
                dashboardIndex={dashboardIndex}
              />
            </React.Fragment>
          );
        })}
      </ol>
      <br />
      {cavcIssues.length > 0 &&
        <>
          <div>
            <strong {...headerStyling}>
              <span>{LABELS.CAVC_DASHBOARD_ADDED_ISSUES}</span>
              <span>{LABELS.CAVC_DASHBOARD_DISPOSITIONS}</span>
            </strong>
            <hr />
          </div>
          <ol {...olStyling}>
            {cavcIssues.map((cavcIssue, i) => {
              const issueDisposition = dashboardDispositions.filter((dis) =>
                dis.cavc_dashboard_issue_id === cavcIssue.id);

              return (
                <React.Fragment key={i}>
                  <CavcDashboardIssue
                    issue={cavcIssue}
                    index={i}
                    dispositions={issueDisposition}
                    removeIssueHandler={removeIssueHandler}
                    userCanEdit={userCanEdit}
                    dashboardIndex={dashboardIndex}
                    addedIssueSection
                  />
                </React.Fragment>
              );
            })}
          </ol>
        </>
      }
    </div>
  );
};

CavcDashboardIssue.propTypes = {
  index: PropTypes.number,
  issue: PropTypes.shape({
    benefit_type: PropTypes.string,
    description: PropTypes.string,
    issue_category: PropTypes.string,
    issue_description: PropTypes.string,
    id: PropTypes.number,
  }),
  dispositions: PropTypes.array,
  removeIssueHandler: PropTypes.func,
  addedIssueSection: PropTypes.bool,
  dashboardIndex: PropTypes.number,
  userCanEdit: PropTypes.bool
};

CavcDashboardIssuesSection.propTypes = {
  dashboard: PropTypes.object,
  dashboardIndex: PropTypes.number,
  removeDashboardIssue: PropTypes.func,
  userCanEdit: PropTypes.bool
};

export default CavcDashboardIssuesSection;
