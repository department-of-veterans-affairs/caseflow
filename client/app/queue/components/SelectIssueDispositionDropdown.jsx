import * as React from 'react';
import { connect } from 'react-redux';
import { css } from 'glamor';
import _ from 'lodash';

import SearchableDropdown from '../../components/SearchableDropdown';
import Checkbox from '../../components/Checkbox';

import { COLORS, VACOLS_DISPOSITIONS } from '../constants';
import COPY from '../../../COPY.json';
import UNDECIDED_VACOLS_DISPOSITIONS_BY_ID from '../../../constants/UNDECIDED_VACOLS_DISPOSITIONS_BY_ID.json';
import ISSUE_DISPOSITIONS_BY_ID from '../../../constants/ISSUE_DISPOSITIONS_BY_ID.json';

class SelectIssueDispositionDropdown extends React.PureComponent {
  getStyling = () => {
    const {
      highlight,
      noStyling,
      issue: { disposition }
    } = this.props;

    if (noStyling) {
      return;
    }

    if (highlight && !disposition) {
      return css({
        borderLeft: `4px solid ${COLORS.ERROR}`,
        paddingLeft: '1rem',
        minHeight: '8rem'
      });
    }

    return css({ minHeight: '12rem' });
  }

  getDispositions = () => {
    const { appeal } = this.props;

    if (appeal.isLegacyAppeal) {
      return Object.entries(UNDECIDED_VACOLS_DISPOSITIONS_BY_ID).
        map((opt) => ({
          label: `${opt[0]} - ${String(opt[1])}`,
          value: opt[0]
        }));
    }

    return Object.entries(ISSUE_DISPOSITIONS_BY_ID).map((opt) => ({
      label: opt[1],
      value: opt[0]
    }));
  }

  render = () => {
    const {
      appeal,
      highlight,
      issue
    } = this.props;

    return <div className="issue-disposition-dropdown"{...this.getStyling()}>
      <SearchableDropdown
        placeholder="Select disposition"
        value={issue.disposition}
        hideLabel
        errorMessage={(highlight && !issue.disposition) ? COPY.FORM_ERROR_FIELD_REQUIRED : ''}
        options={this.getDispositions()}
        onChange={(option) => this.props.updateIssue({
          disposition: option ? option.value : null,
          readjudication: false
        })}
        name={`dispositions_dropdown_${String(issue.id)}`} />
      {appeal.isLegacyAppeal && issue.disposition === VACOLS_DISPOSITIONS.VACATED && <Checkbox
        name={`duplicate-vacated-issue-${String(issue.id)}`}
        styling={css({
          marginBottom: 0,
          marginTop: '1rem'
        })}
        onChange={(readjudication) => this.props.updateIssue({ readjudication })}
        value={issue.readjudication}
        label="Automatically create vacated issue for readjudication." />}
    </div>;
  };
}

const mapStateToProps = (state, ownProps) => ({
  highlight: _.isUndefined(ownProps.highlight) ? state.ui.highlightFormItems : ownProps.highlight
});

export default (connect(mapStateToProps)(SelectIssueDispositionDropdown));
