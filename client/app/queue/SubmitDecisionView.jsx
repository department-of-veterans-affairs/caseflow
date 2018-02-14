import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import _ from 'lodash';
import { css } from 'glamor';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import RadioField from '../components/RadioField';
import Checkbox from '../components/Checkbox';
import TextField from '../components/TextField';
import TextareaField from '../components/TextareaField';
import Button from '../components/Button';

import { fullWidth } from './constants';

const smallBottomMargin = css({ marginBottom: '1rem' });
const noBottomMargin = css({ marginBottom: 0 });

// applying question-label styling directly to <legend> in RadioField
// isn't specific enough, is overridden by .cf-form-showhide-radio .question-label
const radioFieldStyling = css(noBottomMargin, {
  marginTop: '2rem',
  '& .question-label': {
    marginBottom: 0
  }
});
const subHeadStyling = css({ marginBottom: '2rem' });
const checkboxStyling = css({ marginTop: '1rem' });
const textAreaStyling = css({ marginTop: '4rem' });

class SubmitDecisionView extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      omo_type: '',
      overtime: false,
      document_id: '',
      notes: '',
      isBlocking: false
    };
  }

  render = () => {
    const omoTypes = [{
      displayText: 'VHA - OMO',
      value: 'omo'
    }, {
      displayText: 'VHA - IME',
      value: 'ime'
    }];

    return <AppSegment filledBackground>
      <h1 className="cf-push-left" {...css(fullWidth, smallBottomMargin)}>
        Submit OMO
      </h1>
      <p className="cf-lead-paragraph" {...subHeadStyling}>
        Review and complete the following details to check this task out for judge review.
      </p>
      <hr />
      <RadioField
        name="omo_type"
        label="OMO type:"
        onChange={(omoType) => this.setState({ omo_type: omoType })}
        value={this.state.omo_type}
        vertical
        required
        options={omoTypes}
        styling={radioFieldStyling}
      />
      <Checkbox
        name="overtime"
        label="This work product is overtime"
        onChange={(overtime) => this.setState({ overtime })}
        value={this.state.overtime}
        styling={css(smallBottomMargin, checkboxStyling)}
      />
      <TextField
        name="Document ID:"
        required
        onChange={(documentId) => this.setState({ document_id: documentId })}
        value={this.state.document_id}
      />
      <span>Check out to:</span><br />
      <span>Nick Kroes</span>
      <Button
        classNames={['cf-btn-link']}
        onClick={_.noop}>
        Select another judge
      </Button>
      <TextareaField
        name="Notes:"
        value={this.state.notes}
        onChange={(notes) => this.setState({ notes })}
        styling={textAreaStyling}
      />
    </AppSegment>;
  };
}

SubmitDecisionView.propTypes = {
  vacolsId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.loadedQueue.appeals[ownProps.vacolsId]
});

export default connect(mapStateToProps)(SubmitDecisionView);
