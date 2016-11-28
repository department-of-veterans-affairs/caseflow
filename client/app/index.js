import ReactOnRails from 'react-on-rails';

// List of container components we render directly in  Rails .erb files
import BaseContainer from './containers/BaseContainer';


// Registering these components with ReactOnRails
ReactOnRails.register({ BaseContainer });
