var exec = require('cordova/exec');

var VinCode = {
	scan: function (success, error) {
		exec(success, error, 'VinCode', 'scan', []);
	},

	getImage: function (success, error) {
		exec(success, error, 'VinCode', 'getImage', []);
	},

	recognizeImageFile: function (file, success, error) {
		exec(success, error, 'VinCode', 'recognizeImageFile', [file]);
	}
};

module.exports = VinCode;
