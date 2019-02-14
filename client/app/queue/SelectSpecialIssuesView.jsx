import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import { setSpecialIssues } from './QueueActions';
import { requestSave } from './uiReducer/uiActions';

import decisionViewBase from './components/DecisionViewBase';
import Alert from '../components/Alert';
import { css } from 'glamor';
import CheckboxGroup from '../components/CheckboxGroup';
import specialIssueFilters from '../constants/SpecialIssueFilters';
import COPY from '../../COPY.json';
import ApiUtil from '../util/ApiUtil';

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
    const { specialIssues } = this.props;

    return this.renderLegacySpecialIssues(specialIssues);
  }
  renderLegacySpecialIssues = (specialIssues) => {
    const {
      error
    } = this.props;
    let sections = [
      specialIssueFilters.aboutSection(),
      specialIssueFilters.residenceSection(),
      specialIssueFilters.benefitTypeSection(),
      specialIssueFilters.issuesOnAppealSection(),
      specialIssueFilters.dicOrPensionSection()];

    // format the section the way the CheckBoxGroup expects it, and sort according to the mock
    sections = sections.map((section) => {
      return section.sort((previous, next) => {
        return previous.queueSectionOrder - next.queueSectionOrder;
      }).map((issue) => {
        return {
          id: issue.snakeCase,
          label: issue.node || issue.queueDisplay || issue.display
        };
      });
    });

    // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Destructuring_assignment
    const [aboutSection, residenceSection, benefitTypeSection, issuesOnAppealSection, dicOrPensionSection] = sections;

    return <React.Fragment>
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
    </React.Fragment>;
  };
}

SelectSpecialIssuesView.propTypes = {
  appealId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.stagedChanges.appeals[ownProps.appealId],
  specialIssues: state.queue.specialIssues,
  error: state.ui.messages.error
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setSpecialIssues,
  requestSave
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(decisionViewBase(SelectSpecialIssuesView));
