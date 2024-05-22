import React from 'react';
import PropTypes from 'prop-types';
// import { Dropdown } from "/client/app/components/Dropdown";

// import { Button } from '/client/app/components/Button';

export default class RemoveContractorModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selectedContractor: null,
    };
  }

  handleContractorSelect = (contractor) => {
    this.setState({ selectedContractor: contractor });
  };

  render() {
    const {
      contractors,
      // closeHandler,
    } = this.props;

    return (
      <div>
        {/* <Dropdown onSelect={this.handleContractorSelect}>
          {contractors.map((contractor, index) => (
            <Dropdown.Item eventKey={contractor} key={index}>
              {contractor}
            </Dropdown.Item>
          ))}
        </Dropdown>
        <Button name="Remove Contractor" onClick={closeHandler} /> */}
        {contractors.map((contractor, index) => (
          <p key={index}>{contractor}</p>
        ))}
      </div>
    );
  }
}

RemoveContractorModal.propTypes = {
  contractors: PropTypes.arrayOf(PropTypes.string).isRequired,
  closeHandler: PropTypes.func.isRequired,
};





// import React from 'react';
// import PropTypes from 'prop-types';
// import { Dropdown } from '/client/app/components/Dropdown';
// import ScrollLock from 'react-scrolllock';
// import { CloseIcon } from '../../components/';
// import { css } from 'glamor';
// import { Button } from '/client/app/components/Button';
// // client / app / components / Button.jsx;

// const modalTextStyling = css({ width: '100%', fontFamily: 'Source Sans Pro' });

// const iconStyling = css({
//   float: 'left',
//   flexGrow: 0,
//   flexShrink: 0,
//   flexBasis: '13%',
//   marginTop: '1rem',
//   color: '#323a45',
// });

// export default class RemoveContractorModal extends React.Component {
//   constructor(props) {
//     super(props);
//     this.state = {
//       selectedContractor: null,
//     };
//     this.buttonIdPrefix = `${this.props.title.replace(/\s/g, '-')}-button-id-`;
//   }

//   handleContractorSelect = (contractor) => {
//     this.setState({ selectedContractor: contractor });
//   };

//   handleSubmit = async () => {
//     const { selectedContractor } = this.state;
//     const response = await fetch('/api/contractors/remove', { // replace with your actual API endpoint
//       method: 'POST',
//       headers: {
//         'Content-Type': 'application/json',
//       },
//       body: JSON.stringify({ contractor: selectedContractor }),
//     });

//     if (response.ok) {
//       // handle successful removal
//       this.props.submitHandler();
//     } else {
//       // handle error
//     }
//   };

//   render() {
//     const {
//       contractors,
//       closeHandler,
//       title,
//       className,
//       id,
//       scrollLock,
//     } = this.props;

//     return (
//       <section
//         className={`cf-modal active ${className}`}
//         id="modal_id"
//         role="dialog"
//         aria-labelledby="modal_id-title"
//         aria-describedby="modal_id-desc"
//         aria-modal="true"
//       >
//         {scrollLock && <ScrollLock />}
//         <div className="cf-modal-body" id={id || ''}>
//           <button
//             type="button"
//             id={`${this.buttonIdPrefix}close`}
//             className="cf-modal-close"
//             onClick={closeHandler}
//           >
//             <span className="usa-sr-only">Close</span>
//             <CloseIcon />
//           </button>
//           <div style={{ display: 'flex' }}>
//             <div {...css({ flexGrow: 1 })}>
//               <h1 id="modal_id-title">{title}</h1>
//               <div {...modalTextStyling}>
//                 This will permanently remove this Contractor from the list of assignable contractors.
//               </div>
//               <Dropdown onSelect={this.handleContractorSelect}>
//                 {contractors.map((contractor, index) => (
//                   <Dropdown.Item eventKey={contractor} key={index}>
//                     {contractor}
//                   </Dropdown.Item>
//                 ))}
//               </Dropdown>
//             </div>
//           </div>
//           <div className="cf-modal-divider" />
//           <div className="cf-modal-controls">
//             <Button name="Cancel" onClick={closeHandler} classNames={['cf-push-left']} />
//             <Button name="Submit" onClick={this.handleSubmit} classNames={['cf-push-right']} />
//           </div>
//         </div>
//       </section>
//     );
//   }
// }

// RemoveContractorModal.propTypes = {
//   availableContractors: PropTypes.arrayOf(PropTypes.string).isRequired,
//   closeHandler: PropTypes.func.isRequired,
//   submitHandler: PropTypes.func.isRequired,
//   title: PropTypes.string.isRequired,
//   className: PropTypes.string,
//   id: PropTypes.string,
//   scrollLock: PropTypes.bool,
// };

// RemoveContractorModal.defaultProps = {
//   className: '',
//   scrollLock: true,
// };
