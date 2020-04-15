import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import { setSpecialIssues } from './QueueActions';
import { requestSave, showErrorMessage } from './uiReducer/uiActions';

import Alert from '../components/Alert';
import { css } from 'glamor';
import CheckboxGroup from '../components/CheckboxGroup';
import specialIssueFilters from '../constants/SpecialIssueFilters';
import COPY from '../../COPY';
import ApiUtil from '../util/ApiUtil';
import QueueFlowPage from './components/QueueFlowPage';

const flexContainer = css({
  display: 'flex',
  justifyContent: 'space-between'
});
const flexColumn = css({
  flexDirection: 'row',
  flexWrap: 'wrap',
  width: '50%'
});

class SelectSpecialIssuesView extends React.PureComponent {
  getPageName = () => COPY.SPECIAL_ISSUES_PAGE_TITLE;
  getPageNote = () => COPY.SPECIAL_ISSUES_PAGE_NOTE;
  onChangeLegacySpecialIssue = (event) => {
    this.props.setSpecialIssues({
      [event.target.id]: document.getElementById(event.target.id).checked
    });
  }

  validateForm = () => {
    if (!this.props.featureToggles.special_issues_revamp) {
      return true;
    }

    const { specialIssues } = this.props;
    const checkedIssues = Object.entries(specialIssues).filter((entry) => entry[1] === true);
    const isValid = checkedIssues.length > 0;

    if (!isValid) {
      this.props.showErrorMessage(
        { title: COPY.SPECIAL_ISSUES_NONE_CHOSEN_TITLE,
          detail: COPY.SPECIAL_ISSUES_NONE_CHOSEN_DETAIL });
    }

    return isValid;
  };
  goToNextStep = () => {
    const {
      appeal,
      specialIssues
    } = this.props;

    const data = ApiUtil.convertToSnakeCase({ specialIssues });

    this.props.requestSave(`/appeals/${appeal.externalId}/special_issues`, { data }, null).
      catch(() => {
        // handle the error from the frontend
      });
  };
  render() {
    const { appeal, specialIssues } = this.props;

    if (appeal.isLegacyAppeal) {
      return this.renderLegacySpecialIssues(specialIssues);
    }

    return this.renderAmaSpecialIssues(specialIssues);

  }

  sortSectionsAndMapIssues = (sections) => {
    // format the section the way the CheckBoxGroup expects it, and sort according to the mock
    return sections.map((section) => {
      return section.sort((previous, next) => {
        return previous.queueSectionOrder - next.queueSectionOrder;
      }).map((issue) => {
        return {
          id: issue.snakeCase,
          label: issue.node || issue.queueDisplay || issue.display
        };
      });
    });
  }
  renderLegacySpecialIssues = (specialIssues) => {
    const {
      error,
      ...otherProps
    } = this.props;
    const sections = [
      specialIssueFilters(this.props.featureToggles.special_issues_revamp).noneSection(),
      specialIssueFilters(this.props.featureToggles.special_issues_revamp).aboutSection(),
      specialIssueFilters(this.props.featureToggles.special_issues_revamp).residenceSection(),
      specialIssueFilters(this.props.featureToggles.special_issues_revamp).benefitTypeSection(),
      specialIssueFilters(this.props.featureToggles.special_issues_revamp).issuesOnAppealSection(),
      specialIssueFilters(this.props.featureToggles.special_issues_revamp).dicOrPensionSection()];

    // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Destructuring_assignment
    const [
      noneSection,
      aboutSection,
      residenceSection,
      benefitTypeSection,
      issuesOnAppealSection,
      dicOrPensionSection
    ] = this.sortSectionsAndMapIssues(sections);

    return <QueueFlowPage goToNextStep={this.goToNextStep} validateForm={this.validateForm} {...otherProps}>
      <h1>
        {this.getPageName()}
      </h1>
      <p>
        {this.getPageNote()}
      </p>
      {error && <Alert type="error" title={error.title} message={error.detail} />}
      <div {...flexContainer} className="special-options">
        <div {...flexColumn}>
          { this.props.featureToggles.special_issues_revamp && <CheckboxGroup
            label=""
            name=""
            options={noneSection}
            values={specialIssues}
            onChange={this.onChangeLegacySpecialIssue}
          />}
          <CheckboxGroup
            label={<h3>{COPY.SPECIAL_ISSUES_ABOUT_SECTION}</h3>}
            name="About the appellant"
            options={aboutSection}
            values={specialIssues}
            onChange={this.onChangeLegacySpecialIssue}
          />
          <CheckboxGroup
            label={<h3>{COPY.SPECIAL_ISSUES_RESIDENCE_SECTION}</h3>}
            name="Residence"
            options={residenceSection}
            values={specialIssues}
            onChange={this.onChangeLegacySpecialIssue}
          />
          <CheckboxGroup
            label={<h3>{COPY.SPECIAL_ISSUES_BENEFIT_TYPE_SECTION}</h3>}
            name="Benefit Types"
            options={benefitTypeSection}
            values={specialIssues}
            onChange={this.onChangeLegacySpecialIssue}
          />
        </div>
        <div {...flexColumn}>
          <CheckboxGroup
            styling={css({ marginTop: 0 })}
            label={<h3> {COPY.SPECIAL_ISSUES_ISSUES_ON_APPEAL_SECTION}</h3>}
            name="Issues on Appeal"
            options={issuesOnAppealSection}
            values={specialIssues}
            onChange={this.onChangeLegacySpecialIssue}
          />
          <CheckboxGroup
            label={<h3>{COPY.SPECIAL_ISSUES_DIC_OR_PENSION_SECTION} </h3>}
            name="DIC or Pension"
            options={dicOrPensionSection}
            values={specialIssues}
            onChange={this.onChangeLegacySpecialIssue}
          />
        </div>
      </div>
    </QueueFlowPage>;
  };
  renderAmaSpecialIssues = (specialIssues) => {
    const {
      error,
      ...otherProps
    } = this.props;
    const sections = [
      specialIssueFilters(this.props.featureToggles.special_issues_revamp).noneSection(),
      specialIssueFilters(this.props.featureToggles.special_issues_revamp).amaIssuesOnAppealSection()
    ];

    const [
      noneSection,
      issuesOnAppealSection
    ] = this.sortSectionsAndMapIssues(sections);

    return <QueueFlowPage goToNextStep={this.goToNextStep} validateForm={this.validateForm} {...otherProps}>
      <h1>
        {this.getPageName()}
      </h1>
      <p>
        {this.getPageNote()}
      </p>
      {error && <Alert type="error" title={error.title} message={error.detail} />}
      <div {...flexContainer} className="special-options">
        <div {...flexColumn}>
          <CheckboxGroup
            label=""
            name=""
            options={noneSection}
            values={specialIssues}
            onChange={this.onChangeLegacySpecialIssue}
          />
        </div>
        <div {...flexColumn}>
          <CheckboxGroup
            styling={css({ marginTop: 0 })}
            label={<h3> {COPY.SPECIAL_ISSUES_ISSUES_ON_APPEAL_SECTION}</h3>}
            name="Issues on Appeal"
            options={issuesOnAppealSection}
            values={specialIssues}
            onChange={this.onChangeLegacySpecialIssue}
          />
        </div>
      </div>
    </QueueFlowPage>;
  };
}

SelectSpecialIssuesView.propTypes = {
  appeal: PropTypes.shape({
    externalId: PropTypes.string,
    isLegacyAppeal: PropTypes.bool
  }),
  appealId: PropTypes.string.isRequired,
  error: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  }),
  featureToggles: PropTypes.shape({
    special_issues_revamp: PropTypes.bool
  }),
  requestSave: PropTypes.func,
  setSpecialIssues: PropTypes.func,
  showErrorMessage: PropTypes.func,
  specialIssues: PropTypes.object
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.stagedChanges.appeals[ownProps.appealId],
  specialIssues: state.queue.specialIssues,
  error: state.ui.messages.error,
  featureToggles: state.ui.featureToggles
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setSpecialIssues,
  showErrorMessage,
  requestSave
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(SelectSpecialIssuesView);
