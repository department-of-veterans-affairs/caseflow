import ReactOnRails from 'react-on-rails';

// List of container components we render directly in  Rails .erb files
import BaseContainer from './containers/BaseContainer';
import Certification from './certification/Certification'


// Registering these components with ReactOnRails
ReactOnRails.register({ BaseContainer });
ReactOnRails.register({ Certification });
