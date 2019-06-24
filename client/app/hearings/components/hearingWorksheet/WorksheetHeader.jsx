import React from 'react';
import moment from 'moment';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import classNames from 'classnames';
import Textarea from 'react-textarea-autosize';
import { ClipboardIcon } from '../../../components/RenderFunctions';
import CopyToClipboard from 'react-copy-to-clipboard';
import { onRepNameChange, onWitnessChange, onMilitaryServiceChange } from '../../actions/hearingWorksheetActions';
import { css } from 'glamor';
import _ from 'lodash';
import { DISPOSITION_OPTIONS } from '../../constants';
import Tooltip from '../../../components/Tooltip';
import DocketTypeBadge from '../../../components/DocketTypeBadge';

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
  flex: '4',
  marginBottom: '20px',
  marginRight: '1.5rem'
});

const secondColumnStyling = css({
  flex: '6',
  marginBottom: '20px'
});

const secondRowStyling = css({
  flex: '1 100%',
  marginBottom: '20px'
});

class WorksheetHeader extends React.PureComponent {

  onRepNameChange = (event) => this.props.onRepNameChange(event.target.value);
  onWitnessChange = (event) => this.props.onWitnessChange(event.target.value);
  onMilitaryServiceChange = (event) => this.props.onMilitaryServiceChange(event.target.value);

  render() {
    const { worksheet } = this.props;

    let olderVeteran = worksheet.veteran_age > 74;

    const veteranClassNames = classNames({ 'cf-red-text': olderVeteran });

    const getVeteranGender = (genderSymbol) => {
      let gender = '';

      if (genderSymbol === 'M') {
        gender = 'Male';
      } else if (genderSymbol === 'F') {
        gender = 'Female';
      }

      return gender;
    };

    let negativeDispositionOptions = ['no_show', 'postponed', 'cancelled'];

    const getAppellantName = () => {
      if (worksheet.appellant_first_name && worksheet.appellant_last_name) {
        return `${worksheet.appellant_last_name}, ${worksheet.appellant_first_name}`;
      }

      return `${worksheet.veteran_last_name}, ${worksheet.veteran_first_name}`;

    };

    const negativeDispositions = negativeDispositionOptions.includes(worksheet.disposition);

    const dispositionClassNames = classNames({ 'cf-red-text': negativeDispositions });

    const getDisposition = (dispositionSymbol) => {
      const disposition = _.find(DISPOSITION_OPTIONS, { value: dispositionSymbol });

      return disposition ? disposition.label : '';
    };

    return <div>
      <div className="cf-hearings-worksheet-data">
        <div className="title">
          <h1>{`${worksheet.veteran_first_name} ${worksheet.veteran_last_name}`}'s Hearing Worksheet</h1>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h4>VLJ</h4>
          <div className="cf-hearings-headers">{worksheet.judge ? worksheet.judge.full_name : ''}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h4>{!this.props.print ? "HEARING TYPE" : "HEAR. TYPE"}</h4>
          <div className="cf-hearings-headers">{worksheet.readable_request_type}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h4>{!this.props.print ? "REGIONAL OFFICE" : "R.O."}</h4>
          <div className="cf-hearings-headers">{worksheet.regional_office_name}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h4>DATE</h4>
          <div className="cf-hearings-headers">{moment(worksheet.scheduled_for).format('ddd l')}</div>
        </div>
        {worksheet.scheduled_for && new Date(worksheet.scheduled_for) < new Date() &&
          <div className="cf-hearings-worksheet-data-cell">
            <h4>{!this.props.print ? "HEARING DISPOSITION" : "HEAR. DISP."}</h4>
            <div className={classNames('cf-hearings-headers', dispositionClassNames)}>
              {getDisposition(worksheet.disposition)}
            </div>
          </div>
        }
      </div>

      <div className="cf-hearings-worksheet-data">
        <h2 className="cf-hearings-worksheet-header">Veteran/Appellant Information</h2>
        <div className="cf-hearings-worksheet-data-cell">
          <h4>{!this.props.print ? "VETERAN NAME" : "VETERAN"}</h4>
          <div className="cf-hearings-headers"><b>
            {`${worksheet.veteran_last_name}, ${worksheet.veteran_first_name}`}
          </b></div>
        </div>

        <div className="cf-hearings-worksheet-data-cell">
          <h4>VETERAN ID</h4>
          {!this.props.print &&
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
          }
          {this.props.print &&
         <div className="cf-hearings-headers">
           {worksheet.veteran_file_number}
         </div>
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
          <div className="cf-hearings-headers">{getVeteranGender(worksheet.veteran_gender)}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h4>APPELLANT NAME</h4>
          <div className="cf-hearings-headers">{getAppellantName()}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h4>CITY/STATE</h4>
          <div className="cf-hearings-headers">{worksheet.appellant_city && worksheet.appellant_state ?
            `${worksheet.appellant_city}, ${worksheet.appellant_state}` : ''}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h4>{!this.props.print ? "POWER OF ATTORNEY" : "POWER OF ATTY."}</h4>
          <div className="cf-hearings-headers">
            {worksheet.representative}
          </div>
        </div>
      </div>

      <form className="cf-hearings-worksheet-form cf-hearings-form-headers">
        <div {...firstColumnStyling} className="cf-push-left cf-hearings-form-headers">
          <WorksheetFormEntry
            name={!this.props.print ? "Representative Name" : "Representative"}
            value={worksheet.representative_name}
            onChange={this.onRepNameChange}
            id="appellant-vet-rep-name"
            minRows={1}
            maxLength="30"
            print={this.props.print}
          />
        </div>
        <div {...secondColumnStyling} className="cf-push-right cf-hearings-form-headers">
          <WorksheetFormEntry
            name={!this.props.print ? "Witness (W)/Observer (O) and Additional Details" : "Witness/Observer and Misc."}
            value={worksheet.witness}
            onChange={this.onWitnessChange}
            id="appellant-vet-witness"
            minRows={1}
            maxLength="120"
            print={this.props.print}
          />
        </div>
        <div {...secondRowStyling} className="cf-push-left cf-hearings-form-head">
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
const mapStateToProps = (state) => ({
  worksheet: state.hearingWorksheet.worksheet
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
