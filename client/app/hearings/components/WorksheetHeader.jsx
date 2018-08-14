import React from 'react';
import moment from 'moment';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import classNames from 'classnames';
import Textarea from 'react-textarea-autosize';
import { ClipboardIcon } from '../../components/RenderFunctions';
import CopyToClipboard from 'react-copy-to-clipboard';
import { onRepNameChange, onWitnessChange, onMilitaryServiceChange } from '../actions/Dockets';
import { css } from 'glamor';
import _ from 'lodash';
import { DISPOSITION_OPTIONS } from '../constants/constants';
import Tooltip from '../../components/Tooltip';

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
  width: '30%',
  marginBottom: '20px'
});

const secondColumnStyling = css({
  width: '65%',
  marginBottom: '20px'
});

const secondRowStyling = css({
  width: '100%',
  marginBottom: '20px'
});

class WorksheetHeader extends React.PureComponent {

  onRepNameChange = (event) => this.props.onRepNameChange(event.target.value);
  onWitnessChange = (event) => this.props.onWitnessChange(event.target.value);
  onMilitaryServiceChange = (event) => this.props.onMilitaryServiceChange(event.target.value);

  render() {
    const {
      appellant,
      worksheet
    } = this.props;

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

    const negativeDispositions = negativeDispositionOptions.includes(worksheet.disposition);

    const dispositionClassNames = classNames({ 'cf-red-text': negativeDispositions });

    const getDisposition = (dispositionSymbol) => {
      const disposition = _.find(DISPOSITION_OPTIONS, { value: dispositionSymbol });

      return disposition ? disposition.label : '';
    };

    return <div>
      <div className="cf-hearings-worksheet-data">
        <div className="title">
          <h1>{worksheet.veteran_mi_formatted}'s Hearing Worksheet</h1>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h5>VLJ</h5>
          <div className="cf-hearings-headers">{worksheet.user ? worksheet.user.full_name : ''}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h5>HEARING TYPE</h5>
          <div className="cf-hearings-headers">{worksheet.request_type}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h5>REGIONAL OFFICE</h5>
          <div className="cf-hearings-headers">{worksheet.regional_office_name}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h5>DATE</h5>
          <div className="cf-hearings-headers">{moment(worksheet.date).format('ddd l')}</div>
        </div>
        {worksheet.date && new Date(worksheet.date) < new Date() &&
          <div className="cf-hearings-worksheet-data-cell">
            <h5>HEARING DISPOSITION</h5>
            <div className={classNames('cf-hearings-headers', dispositionClassNames)}>
              {getDisposition(worksheet.disposition)}
            </div>
          </div>
        }
      </div>

      <div className="cf-hearings-worksheet-data">
        <h2 className="cf-hearings-worksheet-header">Appellant/Veteran Information</h2>
        <div className="cf-hearings-worksheet-data-cell">
          <h5>VETERAN NAME</h5>
          <div className="cf-hearings-headers"><b>{worksheet.veteran_mi_formatted}</b></div>
        </div>

        <div className="cf-hearings-worksheet-data-cell">
          <h5>VETERAN ID</h5>
          {!this.props.print &&
          <div {...copyButtonStyling}>
            <Tooltip text="Click to copy to clipboard">
              <CopyToClipboard text={worksheet.sanitized_vbms_id}>
                <button
                  name="Copy Veteran ID"
                  className={['usa-button-outline cf-copy-to-clipboard']}>
                  {worksheet.sanitized_vbms_id}
                  <ClipboardIcon />
                </button>
              </CopyToClipboard>
            </Tooltip>
          </div>
          }
          {this.props.print &&
         <div className="cf-hearings-headers">
           {worksheet.sanitized_vbms_id}
         </div>
          }
        </div>

        <div className="cf-hearings-worksheet-data-cell">
          <h5>AGE</h5>
          <div className={classNames('cf-hearings-headers', veteranClassNames)}>{worksheet.veteran_age}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h5>GENDER</h5>
          <div className="cf-hearings-headers">{getVeteranGender(worksheet.veteran_sex)}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell" />
        <div className="cf-hearings-worksheet-data-cell">
          <h5>APPELLANT NAME</h5>
          <div className="cf-hearings-headers">{appellant}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h5>CITY/STATE</h5>
          <div className="cf-hearings-headers">{worksheet.appellant_city && worksheet.appellant_state ?
            `${worksheet.appellant_city}, ${worksheet.appellant_state}` : ''}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h5>REPRESENTATIVE ORG.</h5>
          <div className="cf-hearings-headers">{worksheet.representative}</div>
        </div>
      </div>

      <form className="cf-hearings-worksheet-form cf-hearings-form-headers">
        <div {...firstColumnStyling} className="cf-push-left cf-hearings-form-headers">
          <WorksheetFormEntry
            name="Representative Name"
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
            name="Witness (W)/Observer (O) and Additional Details"
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
  worksheet: state.worksheet
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
