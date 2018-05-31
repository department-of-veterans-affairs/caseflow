import React from 'react';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextField from '../../components/TextField';
import Button from '../../components/Button';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { ISSUE_CATEGORIES} from '../constants'

export default class NonRatedIssue extends React.PureComponent {
  render () {
    return (
      <div className="cf-non-rated-issue">
        <SearchableDropdown
          name="issue-category"
          label="Issue category"
          placeholder="Select or enter..."
          options={ISSUE_CATEGORIES} />

        <TextField
          name="Issue description" />
      </div>
    )
  }
}

// class NonRatedIssue extends React.PureComponent {
//   setIssueCategoryFromDropdown = (issueCategory) => {
//     this.props.setIssueCategory(issueCategory.value);
//   }
//
//   render() {
//     return <div>
//       <SearchableDropdown
//         name="issue-category"
//         label="Issue category"
//         placeholder="Select or enter..."
//         options={ISSUE_CATEGORIES}
//         onChange={this.setIssueCategoryFromDropdown}
//         value={this.props.issueCategory} />
//
//       <TextField
//         name="Issue description"
//         onChange={this.onEmailChange}
//         errorMessage={this.state.certificationCancellationForm.email.errorMessage}
//         value={this.state.emailValue} />
//     </div>;
//   }
// }
//
// export default connect(
//   ({ intake }) => ({
//     formType: intake.formType,
//     intakeId: intake.id
//   }),
//   (dispatch) => bindActionCreators({
//     setIssueCategory
//   }, dispatch)
// )(NonRatedIssue);
//
// class SaveIssueButtonUnconnected extends React.PureComponent {
//   handleClick = () => {
//     this.props.saveIssue();
//   }
//
//   render = () =>
//     <Button
//       name="save-issue"
//       onClick={this.handleClick}
//       legacyStyling={false}
//     >
//       Save
//     </Button>;
// }
//
// export const SaveFormButton = connect(
//   ({ intake }) => ({ formType: intake.formType }),
//   (dispatch) => bindActionCreators({
//     clearSearchErrors
//   }, dispatch)
// )(SelectFormButtonUnconnected);
