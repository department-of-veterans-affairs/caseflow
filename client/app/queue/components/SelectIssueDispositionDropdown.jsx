import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import StringUtil from '../../util/StringUtil';

import SearchableDropdown from '../../components/SearchableDropdown';
import Checkbox from '../../components/Checkbox';

import {
  COLORS,
  ERROR_FIELD_REQUIRED
} from '../constants';

// todo: map to VACOLS attrs
const issueDispositionOptions = [
  [1, 'Allowed'],
  [3, 'Remanded'],
  [4, 'Denied'],
  [5, 'Vacated'],
  [6, 'Dismissed, Other'],
  [8, 'Dismissed, Death'],
  [9, 'Withdrawn']
];

const dropdownStyling = (highlight, issueDisposition) => {
  if (highlight && !issueDisposition) {
    return css({
      borderLeft: `4px solid ${COLORS.ERROR}`,
      paddingLeft: '1rem',
      minHeight: '8rem'
    });
  }

  return css({
    minHeight: '12rem'
  });
};

class SelectIssueDispositionDropdown extends React.PureComponent {
  render = () => {
    const {
      highlight,
      issue
    } = this.props;

    return <div className="issue-disposition-dropdown"{...dropdownStyling(highlight, issue.disposition)}>
      <SearchableDropdown
        placeholder="Select Disposition"
        value={issue.disposition}
        hideLabel
        errorMessage={(highlight && !issue.disposition) ? ERROR_FIELD_REQUIRED : ''}
        options={issueDispositionOptions.map((opt) => ({
          label: `${opt[0]} - ${opt[1]}`,
          value: StringUtil.convertToCamelCase(opt[1])
        }))}
        onChange={({ value }) => this.props.updateIssue({
          disposition: value,
          duplicate: false
        })}
        name={`dispositions_dropdown_${issue.vacols_sequence_id}`} />
      {issue.disposition === 'vacated' && <Checkbox
        name="duplicate-vacated-issue"
        styling={css({
          marginBottom: 0,
          marginTop: '1rem'
        })}
        onChange={(duplicate) => this.props.updateIssue({ duplicate })}
        label="Automatically create vacated issue for readjudication." />}
    </div>;
  };
}

SelectIssueDispositionDropdown.propTypes = {
  issue: PropTypes.object.isRequired,
  vacolsId: PropTypes.string.isRequired,
  highlight: PropTypes.bool,
  updateIssue: PropTypes.func.isRequired
};

const mapStateToProps = (state) => ({
  highlight: state.ui.highlightFormItems
});

export default connect(mapStateToProps)(SelectIssueDispositionDropdown);
