import React from 'react';
import moment from 'moment';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import classNames from 'classnames';
import Textarea from 'react-textarea-autosize';
import PropTypes from 'prop-types';
import { ClipboardIcon } from '../../../components/RenderFunctions';
import CopyToClipboard from 'react-copy-to-clipboard';
import { onRepNameChange, onWitnessChange, onMilitaryServiceChange } from '../../actions/hearingWorksheetActions';
import { css } from 'glamor';
import _ from 'lodash';
import { DISPOSITION_OPTIONS } from '../../constants';
import Tooltip from '../../../components/Tooltip';
import DocketTypeBadge from '../../../components/DocketTypeBadge';
import { formatNameLong, formatNameLongReversed } from '../../../util/FormatUtil';

class WorksheetFormEntry extends React.PureComponent {
  render() {
    const textAreaProps = {
      minRows: 3,
      maxRows: 5000,
      value: this.props.value || '',
      ..._.pick(
        this.props,
        [
          'name',
          'onChange',
          'id',
          'minRows',
          'maxLength'
        ]
      )
    };

    return <div className="cf-hearings-worksheet-data">
      <label htmlFor={this.props.id}>{this.props.name}</label>
      {this.props.print ?
        <p>{this.props.value}</p> :
        <Textarea {...textAreaProps} />}
    </div>;
  }
}

const copyButtonStyling = css({
  marginTop: '-18px',
  marginBottom: '10px'
});

const firstColumnStyling = css({
  flex: '40%'
});

const secondColumnStyling = css({
  flex: '60%'
});

const secondRowStyling = css({
  flex: '100%'
});

class WorksheetHeader extends React.PureComponent {

  onRepNameChange = (event) => this.props.onRepNameChange(event.target.value);
  onWitnessChange = (event) => this.props.onWitnessChange(event.target.value);
  onMilitaryServiceChange = (event) => this.props.onMilitaryServiceChange(event.target.value);

  getVeteranGender = (genderSymbol) => {
    let gender = '';

    if (genderSymbol === 'M') {
      gender = 'Male';
    } else if (genderSymbol === 'F') {
      gender = 'Female';
    }

    return gender;
  }

  getAppellantName = (worksheet) => {
    if (worksheet.appellant_first_name && worksheet.appellant_last_name) {
      return formatNameLongReversed(worksheet.appellant_first_name, worksheet.appellant_last_name);
    }

    return formatNameLongReversed(worksheet.veteran_first_name, worksheet.veteran_last_name);
  }

  getDisposition = (dispositionSymbol) => {
    const disposition = _.find(DISPOSITION_OPTIONS, { value: dispositionSymbol });

    return disposition ? disposition.label : '';
  }

  render() {
    const { worksheet } = this.props;
    const olderVeteran = worksheet.veteran_age > 74;
    const veteranClassNames = classNames({ 'cf-red-text': olderVeteran });
    const negativeDispositionOptions = ['no_show', 'postponed', 'cancelled'];
    const negativeDispositions = negativeDispositionOptions.includes(worksheet.disposition);
    const dispositionClassNames = classNames({ 'cf-red-text': negativeDispositions });

    return <div>
      <div className="title">
        <h1>
          {`${formatNameLong(worksheet.veteran_first_name, worksheet.veteran_last_name)}`}'s Hearing Worksheet
        </h1>
      </div>

      <div className="cf-hearings-worksheet-data">
        <div className="cf-hearings-worksheet-data-cell">
          <h4>VLJ</h4>
          <div className="cf-hearings-headers">{worksheet.judge ? worksheet.judge.full_name : ''}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h4>{this.props.print ? 'HEAR. TYPE' : 'HEARING TYPE'}</h4>
          <div className="cf-hearings-headers">{worksheet.readable_request_type}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h4>{this.props.print ? 'R.O.' : 'REGIONAL OFFICE'}</h4>
          <div className="cf-hearings-headers">{worksheet.regional_office_name}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h4>DATE</h4>
          <div className="cf-hearings-headers">{moment(worksheet.scheduled_for).format('ddd l')}</div>
        </div>
        {worksheet.scheduled_for && new Date(worksheet.scheduled_for) < new Date() &&
          <div className="cf-hearings-worksheet-data-cell">
            <h4>{this.props.print ? 'HEAR. DISP.' : 'HEARING DISPOSITION'}</h4>
            <div className={classNames('cf-hearings-headers', dispositionClassNames)}>
              {this.getDisposition(worksheet.disposition)}
            </div>
          </div>
        }
      </div>

      <div className="cf-hearings-worksheet-data">
        <h2 className="cf-hearings-worksheet-header">Veteran/Appellant Information</h2>
        <div className="cf-hearings-worksheet-data-cell">
          <h4>{this.props.print ? 'VETERAN' : 'VETERAN NAME'}</h4>
          <div className="cf-hearings-headers"><b>
            {`${formatNameLongReversed(worksheet.veteran_first_name, worksheet.veteran_last_name)}`}
          </b></div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h4>VETERAN ID</h4>
          {
            this.props.print ? (
              <div className="cf-hearings-headers">
                {worksheet.veteran_file_number}
              </div>
            ) : (
              <div {...copyButtonStyling}>
                <Tooltip text="Click to copy to clipboard">
                  <CopyToClipboard text={worksheet.veteran_file_number}>
                    <button
                      name="Copy Veteran ID"
                      className={['usa-button-secondary cf-copy-to-clipboard']}>
                      {worksheet.veteran_file_number}
                      <ClipboardIcon />
                    </button>
                  </CopyToClipboard>
                </Tooltip>
              </div>
            )
          }
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h4>DOCKET</h4>
          <div>
            <DocketTypeBadge name={worksheet.docket_name} number={worksheet.docket_number} />
            {worksheet.docket_number}
          </div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h4>AGE</h4>
          <div className={classNames('cf-hearings-headers', veteranClassNames)}>{worksheet.veteran_age}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h4>GENDER</h4>
          <div className="cf-hearings-headers">{this.getVeteranGender(worksheet.veteran_gender)}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h4>{this.props.print ? 'APPELLANT' : 'APPELLANT NAME'}</h4>
          <div className="cf-hearings-headers">{this.getAppellantName(worksheet)}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h4>CITY/STATE</h4>
          <div className="cf-hearings-headers">
            {worksheet.appellant_city && worksheet.appellant_state ?
              `${worksheet.appellant_city}, ${worksheet.appellant_state}` : ''}
          </div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h4>{this.props.print ? 'POWER OF ATTY.' : 'POWER OF ATTORNEY'}</h4>
          <div className="cf-hearings-headers">
            {worksheet.representative}
          </div>
        </div>
      </div>

      <form className="cf-hearings-worksheet-form">
        <div {...firstColumnStyling}>
          <WorksheetFormEntry
            name={this.props.print ? 'Representative' : 'Representative Name'}
            value={worksheet.representative_name}
            onChange={this.onRepNameChange}
            id="appellant-vet-rep-name"
            minRows={1}
            maxLength="30"
            print={this.props.print}
          />
        </div>
        <div {...secondColumnStyling}>
          <WorksheetFormEntry
            name={this.props.print ? 'Witness/Observer and Misc.' : 'Witness (W)/Observer (O) and Additional Details'}
            value={worksheet.witness}
            onChange={this.onWitnessChange}
            id="appellant-vet-witness"
            minRows={1}
            maxLength="120"
            print={this.props.print}
          />
        </div>
        <div {...secondRowStyling}>
          <WorksheetFormEntry
            name="Periods and circumstances of service"
            value={worksheet.military_service}
            onChange={this.onMilitaryServiceChange}
            id="worksheet-military-service"
            minRows={1}
            maxLength="1000"
            print={this.props.print}
          />
        </div>
      </form>
    </div>;
  }
}

WorksheetHeader.propTypes = {
  print: PropTypes.bool
};

const mapStateToProps = (state, ownProps) => ({
  worksheet: ownProps.worksheet || state.hearingWorksheet.worksheet
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onRepNameChange,
  onWitnessChange,
  onMilitaryServiceChange
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(WorksheetHeader);
