import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import StringUtil from '../util/StringUtil';
import _ from 'lodash';

import { setDecisionOptions } from './QueueActions';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import RadioField from '../components/RadioField';
import Checkbox from '../components/Checkbox';
import TextField from '../components/TextField';
import TextareaField from '../components/TextareaField';
import Button from '../components/Button';

import { fullWidth } from './constants';
import SearchableDropdown from '../components/SearchableDropdown';

const smallBottomMargin = css({ marginBottom: '1rem' });
const noBottomMargin = css({ marginBottom: 0 });

const radioFieldStyling = css(noBottomMargin, {
  marginTop: '2rem',
  '& .question-label': {
    marginBottom: 0
  }
});
const subHeadStyling = css({ marginBottom: '2rem' });
const checkboxStyling = css({ marginTop: '1rem' });
const textAreaStyling = css({ marginTop: '4rem' });
const selectJudgeButtonStyling = (selectedJudge) => css({ paddingLeft: selectedJudge ? '' : 0 });

class SubmitDecisionView extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      selectingJudge: false
    };
  }

  getJudgeSelectComponent = () => {
    if (this.state.selectingJudge) {
      return <React.Fragment>
        <SearchableDropdown
          name="Select a judge"
          placeholder="Select a judge&hellip;"
          options={_.map(this.props.judges, (judge) => ({
            label: judge.full_name,
            value: judge.css_id
          }))}
          onChange={(judge) => {
            this.setState({ selectingJudge: false });
            this.props.setDecisionOptions({ judge });
          }}
          hideLabel />
      </React.Fragment>;
    }

    const selectedJudge = _.get(this.props.decision.opts.judge, 'label');

    return <React.Fragment>
      {selectedJudge && <span>{selectedJudge}</span>}
      <Button
        id="select-judge"
        classNames={['cf-btn-link']}
        willNeverBeLoading
        styling={selectJudgeButtonStyling(selectedJudge)}
        onClick={() => this.setState({ selectingJudge: true })}>
        Select {selectedJudge ? 'another' : 'a'} judge
      </Button>
    </React.Fragment>;
  }

  render = () => {
    const omoTypes = [{
      displayText: 'VHA - OMO',
      value: 'omo'
    }, {
      displayText: 'VHA - IME',
      value: 'ime'
    }];
    const {
      type: decisionType,
      opts: decisionOpts
    } = this.props.decision;
    const decisionTypeDisplay = decisionType === 'omo' ? 'OMO' : StringUtil.titleCase(decisionType);

    return <AppSegment filledBackground>
      <h1 className="cf-push-left" {...css(fullWidth, smallBottomMargin)}>
        Submit {decisionTypeDisplay} for Review
      </h1>
      <p className="cf-lead-paragraph" {...subHeadStyling}>
        Complete the details below to submit this {decisionTypeDisplay} request for judge review.
      </p>
      <hr />
      {decisionType === 'omo' && <RadioField
        name="omo_type"
        label="OMO type:"
        onChange={(omoType) => this.props.setDecisionOptions({ omoType })}
        value={decisionOpts.omoType}
        vertical
        required
        options={omoTypes}
        styling={radioFieldStyling}
      />}
      <Checkbox
        name="overtime"
        label="This work product is overtime"
        onChange={(overtime) => this.props.setDecisionOptions({ overtime })}
        value={decisionOpts.overtime}
        styling={css(smallBottomMargin, checkboxStyling)}
      />
      <TextField
        label="Document ID:"
        name="document_id"
        required
        onChange={(documentId) => this.props.setDecisionOptions({ documentId })}
        value={decisionOpts.documentId}
      />
      <span>Submit to judge:</span><br />
      {this.getJudgeSelectComponent()}
      <TextareaField
        label="Notes:"
        name="notes"
        value={decisionOpts.notes}
        onChange={(notes) => this.props.setDecisionOptions({ notes })}
        styling={textAreaStyling}
      />
    </AppSegment>;
  };
}

SubmitDecisionView.propTypes = {
  vacolsId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.loadedQueue.appeals[ownProps.vacolsId],
  decision: state.queue.taskDecision,
  judges: state.queue.judges
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setDecisionOptions
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(SubmitDecisionView);
