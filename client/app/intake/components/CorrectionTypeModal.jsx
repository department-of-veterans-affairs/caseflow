import React from 'react';
import PropTypes from 'prop-types';

import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import { correctIssue } from '../actions/addIssues';
import Modal from '../../components/Modal';
import Dropdown from '../../components/Dropdown';


class CorrectionTypeModal extends React.Component {
    constructor(props) {
        super(props)
        this.state = {
            correctionType: 'control'
        }
    }

    handleSelect(correctionType) {
        this.setState({ correctionType })
    }

    render() {
        const {
            issueIndex
        } = this.props;

        return <div className="intake-correction-type">
            <Modal
                buttons={[
                    {
                        classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
                        name: 'Cancel',
                        onClick: this.props.onCancel
                    },
                    {
                        classNames: ['usa-button-red', 'correction-type-submit'],
                        name: 'Correct Issue',
                        onClick: () => {
                            this.props.correctIssue({ index: issueIndex, correctionType: this.state.correctionType });
                            this.props.onClose();
                        }
                    }
                ]}
                visible
                closeHandler={this.props.onClose}
                title="Correct issue"
            >

                <div>
                    <p>This issue will be added to a 930 EP for correction. If a mistake was found during quality review, please select whether it was discovered by the local or national quality review team. Otherwise, select control.</p>

                    <Dropdown
                        name="correctionType"
                        label="Correction Type:"
                        options={[
                            { value: 'control', displayText: 'Control' },
                            { value: 'local_quality_error', displayText: 'Local Quality Error' },
                            { value: 'national_quality_error', displayText: 'National Quality Error' }
                        ]}
                        value={this.state.correctionType}
                        onChange={val => this.handleSelect(val)}
                    />
                </div>

            </Modal>
        </div>;
    }
}

CorrectionTypeModal.propTypes = {
    onCancel: PropTypes.func,
    onClose: PropTypes.func,
    issueIndex: PropTypes.number,
}

export default connect(
    null,
    (dispatch) => bindActionCreators({
        correctIssue
    }, dispatch)
)(CorrectionTypeModal);
