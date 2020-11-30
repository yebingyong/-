var exec = require('cordova/exec');

var PlateCode = {
	scan: function (success, error) {
		exec(success, error, 'PlateCode', 'scan', []);
	},
};

module.exports = PlateCode;
