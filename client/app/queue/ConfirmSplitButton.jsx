import ReactDOM from 'react-dom';
import axios from 'axios';

class ConfirmSplitButton extends React.Component

    handleClick = async() => {
      const data = await axios.axios.post('/user', {
          firstName: 'Fred',
          lastName: 'Flintstone'
      })
      .then(function (response) {
          console.log(response);
      })
      .catch(function (error) {
          console.log(error);
      })
      };  
      return (
          <div className="splitcontainer">
          <h2>Example component</h2>
          <button onClick = {this.handleClick}>Post Split Appeal</button>
          <div>
      {appeal.loading?'':
              appeal.data.data[0].name}
          </div>
      </div>
    );

    export default ConfirmSplitButton;
    if (document.getElementById('root')) {
    ReactDOM.render(<ConfirmSplitButton />, document.getElementById('root'));
}
