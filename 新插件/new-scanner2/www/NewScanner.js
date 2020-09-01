var exec = require('cordova/exec');

var NewScanner = {
	coolMethod: function (token, success, error) {
		exec(success, error, 'NewScanner', 'coolMethod', [token]);
	},
};

module.exports = NewScanner;
