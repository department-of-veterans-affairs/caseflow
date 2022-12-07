import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import { setSpecialIssues, clearSpecialIssues } from './QueueActions';
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
  constructor(props) {
    super(props);

    this.state = {
      allIssuesDisabled: props.specialIssues.no_special_issues
    };
  }

  getPageName = () => COPY.SPECIAL_ISSUES_PAGE_TITLE;
  getPageNote = () => COPY.SPECIAL_ISSUES_PAGE_NOTE;
  onChangeSpecialIssue = (event) => {
    const specialIssueId = event.target.id;
    const checked = document.getElementById(specialIssueId).checked;

    if (specialIssueId === 'no_special_issues') {
      this.setState({ allIssuesDisabled: checked });
      if (checked) {
        this.props.clearSpecialIssues();
      }
    }
    this.props.setSpecialIssues({
      [specialIssueId]: checked
    });
  }

  validateForm = () => {

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
    const sections = (appeal.isLegacyAppeal) ? this.legacySpecialIssuesSections() : this.amaSpecialIssuesSections();

    return this.renderSpecialIssuesPage(appeal, sections, specialIssues);
  }

  legacySpecialIssuesSections = () => {
    return [
      specialIssueFilters(true).noneSection(),
      specialIssueFilters(true).aboutSection(),
      specialIssueFilters(true).residenceSection(),
      specialIssueFilters(true).benefitTypeSection(),
      specialIssueFilters(true).issuesOnAppealSection(),
      specialIssueFilters(true).dicOrPensionSection()
    ];
  };
  amaSpecialIssuesSections = () => {
    return [
      specialIssueFilters(true).noneSection(),
      specialIssueFilters(true).amaIssuesOnAppealSection()
    ];
  };

  sortAndConvertIssues = (sections) => {
    // convert sections array to a map for easier conditional rendering of CheckboxGroups
    return sections.reduce((map, section) => {
      if (section.length > 0) {
        // format the section the way the CheckBoxGroup expects it, and sort according to the mock
        const issueList = section.sort((previous, next) => {
          return previous.queueSectionOrder - next.queueSectionOrder;
        }).map((issue) => {
          return {
            id: issue.snakeCase,
            label: issue.node || issue.queueDisplay || issue.display
          };
        });

        // assumes all issues in issueList is in the same queueSection, which they should be
        map[section[0].queueSection] = issueList;
      }

      return map;
    }, {});
  };

  renderSpecialIssuesPage = (appeal, sections, specialIssues) => {
    const {
      error,
      ...otherProps
    } = this.props;
    const { allIssuesDisabled } = this.state;
    const sectionsMap = this.sortAndConvertIssues(sections);

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
          {
            sectionsMap.noSpecialIssues && <CheckboxGroup
              label=""
              name=""
              options={sectionsMap.noSpecialIssues}
              values={specialIssues}
              onChange={this.onChangeSpecialIssue}
            />
          }
          { /* For AMA cases, show the 'issuesOnAppeal' section in the first column.
               For Legacy cases, show it in the second column.
             */
            !appeal.isLegacyAppeal && sectionsMap.issuesOnAppeal &&
            this.issuesOnAppealCheckboxGroup(sectionsMap, specialIssues)
          }
          {
            sectionsMap.about && <CheckboxGroup
              label={<h3>{COPY.SPECIAL_ISSUES_ABOUT_SECTION}</h3>}
              name="About the appellant"
              options={sectionsMap.about}
              values={specialIssues}
              onChange={this.onChangeSpecialIssue}
              disableAll={allIssuesDisabled}
            />
          }
          {
            sectionsMap.residence && <CheckboxGroup
              label={<h3>{COPY.SPECIAL_ISSUES_RESIDENCE_SECTION}</h3>}
              name="Residence"
              options={sectionsMap.residence}
              values={specialIssues}
              onChange={this.onChangeSpecialIssue}
              disableAll={allIssuesDisabled}
            />
          }
          {
            sectionsMap.benefitType && <CheckboxGroup
              label={<h3>{COPY.SPECIAL_ISSUES_BENEFIT_TYPE_SECTION}</h3>}
              name="Benefit Types"
              options={sectionsMap.benefitType}
              values={specialIssues}
              onChange={this.onChangeSpecialIssue}
              disableAll={allIssuesDisabled}
            />
          }
        </div>
        <div {...flexColumn}>
          { /* For AMA cases, show the 'issuesOnAppeal' section in the first column.
               For Legacy cases, show it in the second column.
             */
            appeal.isLegacyAppeal && sectionsMap.issuesOnAppeal &&
            this.issuesOnAppealCheckboxGroup(sectionsMap, specialIssues)
          }
          {
            sectionsMap.dicOrPension && <CheckboxGroup
              label={<h3>{COPY.SPECIAL_ISSUES_DIC_OR_PENSION_SECTION} </h3>}
              name="DIC or Pension"
              options={sectionsMap.dicOrPension}
              values={specialIssues}
              onChange={this.onChangeSpecialIssue}
              disableAll={allIssuesDisabled}
            />
          }
        </div>
      </div>
    </QueueFlowPage>;
  };

  issuesOnAppealCheckboxGroup = (sectionsMap, specialIssues) => {
    return <CheckboxGroup
      styling={css({ marginTop: 0 })}
      label={<h3> {COPY.SPECIAL_ISSUES_ISSUES_ON_APPEAL_SECTION}</h3>}
      name="Issues on Appeal"
      options={sectionsMap.issuesOnAppeal}
      values={specialIssues}
      onChange={this.onChangeSpecialIssue}
      disableAll={this.state.allIssuesDisabled}
    />;
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
  requestSave: PropTypes.func,
  setSpecialIssues: PropTypes.func,
  clearSpecialIssues: PropTypes.func,
  showErrorMessage: PropTypes.func,
  specialIssues: PropTypes.object
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.stagedChanges.appeals[ownProps.appealId],
  specialIssues: state.queue.specialIssues,
  error: state.ui.messages.error,
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setSpecialIssues,
  clearSpecialIssues,
  showErrorMessage,
  requestSave
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(SelectSpecialIssuesView);
