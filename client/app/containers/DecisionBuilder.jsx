import React, { PropTypes } from 'react';

import SearchableDropDown from '../components/SearchableDropDown';
import Table from '../components/Table';
import Button from '../components/Button';
import ApiUtil from '../util/ApiUtil';

import {
          FormField,
          handleFieldChange,
          getFormValues,
          validateFormAndSetErrors
       } from '../util/FormField';

const DEFINE_ISSUE_TYPE = 0;
const DEFINE_ISSUE_SUBTYPE = 1;
const DEFINE_RATING = 2;
const CONFIRM = 3;

const ISSUE_TYPES = {
  'Knee & Leg': {
    'Ankylosis': {
      '30%': 'Favorable angle in full extension, or in slight flexion between 0\u00B0 and 10\u00B0',
      '40%': 'Flexion between 10\u00B0 and 20\u00B0',
      '50%': 'Flexion between 20\u00B0 and 45\u00B0',
      '60%': 'Extremely unfavorable, in flexion at an angle of 45\u00B0 or more'
    },
    'Impairment of: Recurrent subluxation or lateral instability': {
      '10%': 'Slight',
      '20%': 'Moderate',
      '30%': 'Severe'
    },
    'Cartilage, semilunar, disolacted, with frequent episodes of "locking," pain, and effusion into the joint': {
      '20%': 'Exists'
    },
  }, 
  Joint: {
    'Ankylosis': {
      '30%': 'Favorable angle in full extension, or in slight flexion between 0\u00B0 and 10\u00B0',
      '40%': 'Flexion between 10\u00B0 and 20\u00B0',
      '50%': 'Flexion between 20\u00B0 and 45\u00B0',
      '60%': 'Extremely unfavorable, in flexion at an angle of 45\u00B0 or more'
    },
    'Impairment of: Recurrent subluxation or lateral instability': {
      '10%': 'Slight',
      '20%': 'Moderate',
      '30%': 'Severe'
    },
    'Cartilage, semilunar, disolacted, with frequent episodes of "locking," pain, and effusion into the joint': {
      '20%': 'Exists'
    },
  },
  Arthritis: {
    'Ankylosis': {
      '30%': 'Favorable angle in full extension, or in slight flexion between 0\u00B0 and 10\u00B0',
      '40%': 'Flexion between 10\u00B0 and 20\u00B0',
      '50%': 'Flexion between 20\u00B0 and 45\u00B0',
      '60%': 'Extremely unfavorable, in flexion at an angle of 45\u00B0 or more'
    },
    'Impairment of: Recurrent subluxation or lateral instability': {
      '10%': 'Slight',
      '20%': 'Moderate',
      '30%': 'Severe'
    },
    'Cartilage, semilunar, disolacted, with frequent episodes of "locking," pain, and effusion into the joint': {
      '20%': 'Exists'
    },
  }
};

export default class DecisionBuilder extends React.Component {
  constructor(props) {
    super(props);
    
    this.handleFieldChange = handleFieldChange.bind(this);
    
    this.state = {
      step: DEFINE_ISSUE_TYPE,
      form: {
        issueType: new FormField(''),
        issueSubType: new FormField('')
      },
      issueList: [],
      rating: ''
    };
  }

  showNextField = (currentStep) => {
    return (event) => {
      let step = currentStep;
      if (event.target.value) {
        step = step + 1;
      }

      this.setState({
        step: step
      })
    }
  }

  handleRating = (rating) =>{
    return (event) => {
      this.setState({
        rating: rating,
        step: CONFIRM
      });
    }
  }

  nextIssue = (event) => {
    let issue = {
        type: this.state.form.issueType.value,
        subType: this.state.form.issueSubType.value,
        rating: this.state.rating
      };
    let issueList = this.state.issueList.concat(issue);
    this.setState({
      step: DEFINE_ISSUE_TYPE,
      issueList: issueList,
      form: {
        issueType: new FormField(''),
        issueSubType: new FormField('')
      },
      rating: ''
    });
  }

  submitIssues = (event) => {
    let { handleAlert, handleAlertClear } = this.props;

    event.preventDefault();
    handleAlertClear();

    let issue = {
        type: this.state.form.issueType.value,
        subType: this.state.form.issueSubType.value,
        rating: this.state.rating
      };
    let issueList = this.state.issueList.concat(issue);

    let data = {
      issueList: ApiUtil.convertToSnakeCase(issueList)
    };

    return ApiUtil.post(`/decision/build/docx`, { data }).then(() => {
      window.location = `/decision/build/download`
      this.setState({
        step: DEFINE_ISSUE_TYPE,
        form: {
          issueType: new FormField(''),
          issueSubType: new FormField('')
        },
        issueList: [],
        rating: ''
      });
    }, () => {
      handleAlert(
        'error',
        'Error',
        'There was an error while submitting the current claim. Please try again later'
      );
    });

  }

  render() {
    return <div>
        <div className="cf-app-segment cf-app-segment--alt">
          <h1>Specify Issue</h1>
          { this.state.step >= DEFINE_ISSUE_TYPE &&
            <SearchableDropDown
             label="Select the type of issue"
             name="issueType"
             options={Object.keys(ISSUE_TYPES)}
             onChange={this.handleFieldChange('form', 'issueType', this.showNextField(DEFINE_ISSUE_TYPE))}
             {...this.state.form.issueType}
            />
          }
          { this.state.step >= DEFINE_ISSUE_SUBTYPE &&
            <SearchableDropDown
             label="Select the sub-type of issue"
             name="issueSubType"
             options={Object.keys(ISSUE_TYPES[this.state.form.issueType.value])}
             onChange={this.handleFieldChange('form', 'issueSubType', this.showNextField(DEFINE_ISSUE_SUBTYPE))}
             {...this.state.form.issueSubType}
            />
          }
          { this.state.step >= DEFINE_RATING &&
            <div>
              <Table
                headers={['Rating', 'Description']}
                values={Object.keys(ISSUE_TYPES[this.state.form.issueType.value][this.state.form.issueSubType.value])}
                buildRowValues={(rating) => [
                  <Button
                    name={rating}
                    onClick={this.handleRating(rating)}
                  />,
                  ISSUE_TYPES[this.state.form.issueType.value][this.state.form.issueSubType.value][rating]
                ]}
              />
            </div>
          }
          { this.state.step >= CONFIRM &&
            <div>
              <div className="cf-push-right">
                <Button
                  name="Next Issue"
                  onClick={this.nextIssue}
                />
                <Button
                  name="Create Document"
                  onClick={this.submitIssues}
                />
              </div>
              <Button
                name="Cancel"
                classNames={["cf-btn-link"]}
              />
            </div>
          }
        </div>
        <div className="cf-app-segment cf-app-segment--alt">
          <h1>Selected Issues</h1>
          {this.state.issueList.map((issue) => {
            return <p>{`${issue.type}--${issue.subType}--${issue.rating}`}</p>
          })}
        </div>
      </div>;
  }
}