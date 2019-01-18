import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { css } from 'glamor';

import CopyTextButton from '../../components/CopyTextButton';
import Alert from '../../components/Alert';
import Button from '../../components/Button';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import * as DateUtil from '../../util/DateUtil';
import ApiUtil from '../../util/ApiUtil';

import {
  Overview,
  Details,
  TranscriptionDetails,
  TranscriptionRequest,
  TranscriptionProblem
} from './DetailsSections';

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

export default class HearingDetails extends React.Component {

  constructor(props) {
    super(props);

    const { hearing } = this.props;
    const transcription = hearing.transcription || {};

    this.state = {
      hearing: {
        bvaPoc: hearing.bvaPoc,
        judgeId: hearing.judgeId ? hearing.judgeId.toString() : null,
        evidenceWindowWaived: hearing.evidenceWindowWaived || false,
        room: hearing.room,
        notes: hearing.notes
      },
      transcription: {
        // Transcription Details
        taskNumber: transcription.taskNumber,
        transcriber: transcription.transcriber,
        sentToTranscriberDate: DateUtil.formatDateStr(transcription.sentToTranscriberDate),
        expectedReturnDate: DateUtil.formatDateStr(transcription.expectedReturnDate),
        uploadedToVbmsDate: DateUtil.formatDateStr(transcription.uploadedToVbmsDate),
        // Transcription Problem
        problemType: transcription.problemType,
        problemNoticeSentDate: DateUtil.formatDateStr(transcription.problemNoticeSentDate),
        requestedRemedy: transcription.requestedRemedy,
        // Transcript Request
        copyRequested: transcription.copyRequested || false,
        copySentDate: DateUtil.formatDateStr(transcription.copySentDate)
      },
      disabled: hearing.docketName !== 'hearing',
      updated: false,
      loading: false,
      success: false,
      error: false
    };
  }

  setHearing = (key, value) => {
    this.setState({
      hearing: {
        ...this.state.hearing,
        [key]: value
      },
      updated: true
    });
  }

  setTranscription = (key, value) => {
    this.setState({
      transcription: {
        ...this.state.transcription,
        [key]: value
      },
      updated: true
    });
  }

  convertDatesForApi = (data) => {
    let converted = { ...data };

    _.forEach(converted, (value, key) => {
      if (key.indexOf('Date') !== -1) {
        converted[key] = DateUtil.formatDateStringForApi(value);
      }
    });

    return converted;
  }

  submit = () => {
    const { hearing: { externalId } } = this.props;
    const { updated, hearing, transcription } = this.state;

    if (!updated) {
      return;
    }

    const data = {
      hearing: this.convertDatesForApi(hearing),
      transcription: this.convertDatesForApi(transcription)
    };

    this.setState({ loading: true });

    ApiUtil.patch(`/hearings/${externalId}`, {
      data: ApiUtil.convertToSnakeCase(data)
    }).then(() => {
      this.setState({
        updated: false,
        loading: false,
        success: true
      });
    }).
      catch((error) => {
        this.setState({
          loading: false,
          error: error.message
        });
      });
  }

  render() {
    const {
      veteranFirstName,
      veteranLastName,
      vbmsId
    } = this.props.hearing;

    const { transcription, hearing, disabled, success, error } = this.state;

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
            <div>Veteran ID: <CopyTextButton text={vbmsId} /></div>
          </div>

          <div className="cf-help-divider" />

          <h2>Hearing Details</h2>
          <Overview hearing={this.props.hearing} />
          <div className="cf-help-divider" />

          <Details
            hearing={hearing}
            set={this.setHearing}
            readOnly={disabled} />
          <div className="cf-help-divider" />

          <h2>Transcription Details</h2>
          <TranscriptionDetails
            transcription={transcription}
            set={this.setTranscription}
            readOnly={disabled} />
          <div className="cf-help-divider" />

          <h2>Transcription Problem</h2>
          <TranscriptionProblem
            transcription={transcription}
            set={this.setTranscription}
            readOnly={disabled} />
          <div className="cf-help-divider" />

          <h2>Transcription Request</h2>
          <TranscriptionRequest
            transcription={transcription}
            set={this.setTranscription}
            readOnly={disabled} />
          <div className="cf-help-divider" />

          <div>
            <a
              className="button-link"
              onClick={this.props.goBack}
              style={{ float: 'left' }}
            >Cancel</a>
            <Button
              name="Save"
              disabled={!this.state.updated || this.state.disabled}
              loading={this.state.loading}
              className="usa-button"
              onClick={this.submit}
              styling={css({ float: 'right' })}
            />
          </div>
        </div>
      </AppSegment>
    );
  }
}

HearingDetails.propTypes = {
  hearing: PropTypes.object.isRequired,
  goBack: PropTypes.func
};
