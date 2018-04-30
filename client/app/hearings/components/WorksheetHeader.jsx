import React from 'react';
import moment from 'moment';
import TextField from '../../components/TextField';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import classNames from 'classnames';
import Textarea from 'react-textarea-autosize';
import { ClipboardIcon } from '../../components/RenderFunctions';
import CopyToClipboard from 'react-copy-to-clipboard';
import { onRepNameChange, onWitnessChange } from '../actions/Dockets';
import { css } from 'glamor';

const copyButtonStyling = css({
  marginTop: '-18px',
  marginBottom: '10px'
});

const columnStyling = css({
  width: '48%'
});

class WorksheetHeader extends React.PureComponent {

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

    return <div>
      <div className="cf-hearings-worksheet-data">
        <div className="title">
          <h1>{appellant}'s Hearing Worksheet</h1>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h5>VLJ</h5>
          <div>{worksheet.user ? worksheet.user.full_name : ''}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h5>HEARING TYPE</h5>
          <div>{worksheet.request_type}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h5>REGIONAL OFFICE</h5>
          <div>{worksheet.regional_office_name}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h5>DATE</h5>
          <div>{moment(worksheet.date).format('ddd l')}</div>
        </div>
      </div>

      <div className="cf-hearings-worksheet-data">
        <h2 className="cf-hearings-worksheet-header">Appellant/Veteran Information</h2>
        <div className="cf-hearings-worksheet-data-cell">
          <h5>VETERAN NAME</h5>
          <div><b>{worksheet.veteran_mi_formatted}</b></div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h5>VETERAN ID</h5>
          <div {...copyButtonStyling}>
            <CopyToClipboard text={worksheet.sanitized_vbms_id}>
              <button
                name="Copy Veteran ID"
                className={['usa-button-outline cf-copy-to-clipboard']}>
                {worksheet.sanitized_vbms_id}
                <ClipboardIcon />
              </button>
            </CopyToClipboard>
          </div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h5>AGE</h5>
          <div className={veteranClassNames}>{worksheet.veteran_age}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h5>GENDER</h5>
          <div>{getVeteranGender(worksheet.veteran_sex)}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell" />
        <div className="cf-hearings-worksheet-data-cell">
          <h5>APPELLANT NAME</h5>
          <div>{appellant}</div>
        </div>
        <div className="cf-hearings-worksheet-data-cell">
          <h5>CITY/STATE</h5>
          <div>{worksheet.appellant_city && worksheet.appellant_state ?
            `${worksheet.appellant_city}, ${worksheet.appellant_state}` : ''}</div>
        </div>
      </div>



      <div {...columnStyling} className="cf-push-left">
        <TextField
          name="Representative Name"
          id="appellant-vet-rep-name"
          aria-label="Representative Name"
          value={worksheet.representative_name || ''}
          onChange={this.props.onRepNameChange}
          maxLength={30}
          fixedInput={this.props.print}
          inline
          strongLabel
        />
      </div>
      <div {...columnStyling} className="cf-push-right">
        <TextField
          name="Representative Org."
          id="appellant-vet-rep-org"
          aria-label="Representative Org."
          value={worksheet.representative || ''}
          onChange={this.props.onRepOrgChange}
          maxLength={50}
          fixedInput={this.props.print}
          inline
          strongLabel
        />
      </div>


      <div {...columnStyling} className="cf-push-left">
        <TextField
          name="Additional Notes"
          id="additional-notes"
          aria-label="Additional Notes"
          value={worksheet.additional_notes || ''}
          onChange={this.props.onAdditionalNotesChange}
          maxLength={50}
          fixedInput={this.props.print}
          inline
          strongLabel
        />
      </div>
      <div {...columnStyling} className="cf-push-right">
        <TextField
          name="Witness (W)/Observer (O)"
          id="appellant-vet-witness"
          aria-label="Witness Observer"
          value={worksheet.witness || ''}
          onChange={this.props.onWitnessChange}
          maxLength={120}
          inline
          strongLabel
        />
      </div>

    </div>;
  }
}
const mapStateToProps = (state) => ({
  worksheet: state.worksheet
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onRepNameChange,
  onWitnessChange
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(WorksheetHeader);
