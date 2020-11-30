var exec = require('cordova/exec');

var PlateVinCodeTest = {
	scan: function (type,success, error) {
		exec(success, error, 'PlateVinCodeTest', 'scan', [type]);
	},

	prepare: function (success, error) {
		exec(success, error, 'PlateVinCodeTest', 'prepare', []);
	},

	show: function (success, error) {
		exec(success, error, 'PlateVinCodeTest', 'show', []);
	},

	hide: function (success, error) {
		exec(success, error, 'PlateVinCodeTest', 'hide', []);
	},

	destroy: function (success, error) {
		exec(success, error, 'PlateVinCodeTest', 'destroy', []);
	},

	disableLight: function (success, error) {
		exec(success, error, 'PlateVinCodeTest', 'disableLight', []);
	},

	enableLight: function (success, error) {
		exec(success, error, 'PlateVinCodeTest', 'enableLight', []);
	},

	useBackCamera: function (success, error) {
		exec(success, error, 'PlateVinCodeTest', 'useBackCamera', []);
	},

	useFrontCamera: function (success, error) {
		exec(success, error, 'PlateVinCodeTest', 'useFrontCamera', []);
	},

	openSettings: function (success, error) {
		exec(success, error, 'PlateVinCodeTest', 'openSettings', []);
	},
	getImage: function (success, error) {
		exec(success, error, 'PlateVinCodeTest', 'getImage', []);
	},
};

module.exports = PlateVinCodeTest;
