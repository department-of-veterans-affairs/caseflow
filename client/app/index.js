import ReactOnRails from 'react-on-rails';

// List of container components we render directly in  Rails .erb files
import EstablishClaim from './containers/EstablishClaim';


// Registering these components with ReactOnRails
ReactOnRails.register({ EstablishClaim });
