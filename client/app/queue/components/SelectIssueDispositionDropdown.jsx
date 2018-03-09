import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import SearchableDropdown from '../../components/SearchableDropdown';

import {
  COLORS,
  ERROR_FIELD_REQUIRED
} from '../constants';
import StringUtil from '../../util/StringUtil';
import { updateAppealIssue } from '../QueueActions';
import Checkbox from '../../components/Checkbox';

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
      issue,
      vacolsId
    } = this.props;

    return <div className="issue-disposition-dropdown"{...dropdownStyling(highlight, issue.disposition)}>
      <SearchableDropdown
        placeholder="Select Dispositions"
        value={issue.disposition}
        hideLabel
        errorMessage={(highlight && !issue.disposition) ? ERROR_FIELD_REQUIRED : ''}
        options={issueDispositionOptions.map((opt) => ({
          label: `${opt[0]} - ${opt[1]}`,
          value: StringUtil.convertToCamelCase(opt[1])
        }))}
        onChange={({ value }) => this.props.updateAppealIssue(vacolsId, issue.id, {
          disposition: value,
          duplicate: false
        })}
        name={`dispositions_dropdown_${issue.id}`} />
      {issue.disposition === 'vacated' && <Checkbox
        name="duplicate-vacated-issue"
        styling={css({
          marginBottom: 0,
          marginTop: '1rem'
        })}
        onChange={(duplicate) => this.props.updateAppealIssue(vacolsId, issue.id, { duplicate })}
        label="Automatically create vacated issue for readjudication." />}
    </div>;
  };
}

SelectIssueDispositionDropdown.propTypes = {
  issue: PropTypes.object.isRequired,
  vacolsId: PropTypes.string.isRequired,
  highlight: PropTypes.bool
};

const mapStateToProps = (state) => ({
  highlight: state.queue.ui.highlightFormItems
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  updateAppealIssue
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(SelectIssueDispositionDropdown);
