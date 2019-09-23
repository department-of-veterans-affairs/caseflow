import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import CopyTextButton from '../../components/CopyTextButton';
import Alert from '../../components/Alert';
import Button from '../../components/Button';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import * as DateUtil from '../../util/DateUtil';
import ApiUtil from '../../util/ApiUtil';

import DetailsSections, { Overview } from './DetailsSections';
import { onChangeFormData } from '../../components/common/actions';

const row = css({
  marginLeft: '-15px',
  marginRight: '-15px',
  '& > *': {
    display: 'inline-block',
    paddingRight: '15px',
    paddingLeft: '15px',
    verticalAlign: 'middle',
    margin: 0
  }
});

const inputFix = css({
  '& .question-label': {
    marginBottom: '2rem !important'
  }
});

const HEARING_DETAILS_FORM_NAME = 'hearingDetails';
const TRANSCRIPTION_DETAILS_FORM_NAME = 'transcriptionDetails';

class HearingDetails extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      disabled: this.props.disabled,
      isLegacy: this.props.hearing.docketName !== 'hearing',
      updated: false,
      loading: false,
      success: false,
      error: false
    };
  }

  componentDidMount() {
    const { hearing } = this.props;
    const transcription = hearing.transcription || {};

    this.props.onChangeFormData(HEARING_DETAILS_FORM_NAME, {
      bvaPoc: hearing.bvaPoc,
      judgeId: hearing.judgeId ? hearing.judgeId.toString() : null,
      evidenceWindowWaived: hearing.evidenceWindowWaived || false,
      room: hearing.room,
      notes: hearing.notes,
      // Transcription Request
      transcriptRequested: hearing.transcriptRequested,
      transcriptSentDate: DateUtil.formatDateStr(hearing.transcriptSentDate, 'YYYY-MM-DD', 'YYYY-MM-DD')
    });

    this.props.onChangeFormData(TRANSCRIPTION_DETAILS_FORM_NAME, {
      // Transcription Details
      taskNumber: transcription.taskNumber,
      transcriber: transcription.transcriber,
      sentToTranscriberDate: DateUtil.formatDateStr(transcription.sentToTranscriberDate, 'YYYY-MM-DD', 'YYYY-MM-DD'),
      expectedReturnDate: DateUtil.formatDateStr(transcription.expectedReturnDate, 'YYYY-MM-DD', 'YYYY-MM-DD'),
      uploadedToVbmsDate: DateUtil.formatDateStr(transcription.uploadedToVbmsDate, 'YYYY-MM-DD', 'YYYY-MM-DD'),
      // Transcription Problem
      problemType: transcription.problemType,
      problemNoticeSentDate: DateUtil.formatDateStr(transcription.problemNoticeSentDate, 'YYYY-MM-DD', 'YYYY-MM-DD'),
      requestedRemedy: transcription.requestedRemedy
    });
  }

  setHearing = (key, value) => {
    this.props.onChangeFormData(HEARING_DETAILS_FORM_NAME, { [key]: value });
    this.setState({ updated: true });
  }

  setTranscription = (key, value) => {
    this.props.onChangeFormData(TRANSCRIPTION_DETAILS_FORM_NAME, { [key]: value });
    this.setState({ updated: true });
  }

  submit = () => {
    const { hearing: { externalId }, hearingDetailsForm, transcriptionDetailsForm } = this.props;
    const { updated } = this.state;

    if (!updated) {
      return;
    }

    const data = {
      hearing: {
        ...hearingDetailsForm,
        transcription_attributes: {
          ...transcriptionDetailsForm
        }
      }
    };

    this.setState({ loading: true });

    ApiUtil.patch(`/hearings/${externalId}`, {
      data: ApiUtil.convertToSnakeCase(data)
    }).then(() => {
      this.setState({
        updated: false,
        loading: false,
        success: true,
        error: false
      });
    }).
      catch((error) => {
        this.setState({
          loading: false,
          error: error.message,
          success: false
        });
      });
  }

  render() {
    const {
      veteranFirstName,
      veteranLastName,
      veteranFileNumber
    } = this.props.hearing;

    const { hearingDetailsForm, transcriptionDetailsForm } = this.props;

    const { disabled, success, error } = this.state;

    return (
      <AppSegment filledBackground>

        {success &&
          <div {...css({ marginBottom: '4rem' })}>
            <Alert type="success" title="Hearing Successfully Updated" />
          </div>
        }{error &&
          <div {...css({ marginBottom: '4rem' })}>
            <Alert type="error" title="There was an error updating hearing" />
          </div>
        }
        <div {...inputFix}>
          <div {...row}>
            <h1 className="cf-margin-bottom-0">{`${veteranFirstName} ${veteranLastName}`}</h1>
            <div>Veteran ID: <CopyTextButton text={veteranFileNumber} label="Veteran ID" /></div>
          </div>

          <div className="cf-help-divider" />
          <h2>Hearing Details</h2>
          <Overview hearing={this.props.hearing} />
          <div className="cf-help-divider" />

          <DetailsSections
            setTranscription={this.setTranscription}
            setHearing={this.setHearing}
            transcription={transcriptionDetailsForm || {}}
            hearing={hearingDetailsForm || {}}
            isLegacy={this.state.isLegacy}
            disabled={disabled} />
          <div>
            <a
              className="button-link"
              onClick={this.props.goBack}
              style={{ float: 'left' }}
            >Cancel</a>
            <span {...css({ float: 'right' })}>
              <Button
                name="Save"
                disabled={!this.state.updated || this.state.disabled}
                loading={this.state.loading}
                className="usa-button"
                onClick={this.submit}
                styling={css({ float: 'right' })}
              >Save</Button>
            </span>
          </div>
        </div>
      </AppSegment>
    );
  }
}

HearingDetails.propTypes = {
  hearing: PropTypes.object.isRequired,
  goBack: PropTypes.func,
  disabled: PropTypes.bool
};

const mapStateToProps = (state) => ({
  hearingDetailsForm: state.components.forms[HEARING_DETAILS_FORM_NAME],
  transcriptionDetailsForm: state.components.forms[TRANSCRIPTION_DETAILS_FORM_NAME]
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onChangeFormData
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingDetails);
