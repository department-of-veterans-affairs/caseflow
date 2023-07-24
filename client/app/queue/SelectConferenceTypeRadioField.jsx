import React, { useState } from 'react';
import RadioField from '../components/RadioField';

// const radioOptions = [
//   { displayText: 'Pexip',
//     value: '1'},
//   { displayText: 'Webex',
//     value: '2'}
// ];

// export default class SelectConferenceTypeRadioField extends React.PureComponent {
//   constructor(props) {
//     super(props);

//     this.state = {
//       value: '1'
//     }
//   }

//   render = () =>
//     <div>
//       <RadioField
//         label="Schedule hearings using:"
//         name=""
//         options={radioOptions}
//         value={this.state.value}
//         onChange={this.setState({value})}
//         vertical
//     /></div>
// }
const radioOptions = [
  { displayText: 'Pexip',
    value: '1'},
  { displayText: 'Webex',
    value: '2'}
];

const SelectConferenceTypeRadioField = () => {
  const [value, setValue] = useState("1")

  return (
    <div >
      <RadioField
        label="Schedule hearings using:"
        name=""
        options={radioOptions}
        value={value}
        onChange={(value) => setValue(value)}
        vertical
    /></div>
  );
}

export default SelectConferenceTypeRadioField;
