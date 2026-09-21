'use strict';
'require view';
'require fs';
'require ui';

var CONFIG_PATH = '/homelab-toolchain/config/export_openwrt_mullvad_values.sh';
var STATUS_SCRIPT = '/homelab-toolchain/openwrt-mullvad/mullvad-connection/get_status.sh';
var SETUP_SCRIPT = '/homelab-toolchain/openwrt-mullvad/mullvad-wireguard-connector/setup.sh';
var RECONNECT_SCRIPT = '/homelab-toolchain/openwrt-mullvad/mullvad-wireguard-connector/connect_or_reconnect.sh';
var SERVERS_DIR = '/homelab-toolchain/openwrt-mullvad/mullvad-metadata-fetcher/fetched/active_servers';

var CONFIG_FIELDS = [
	{ key: 'MULLVAD_LOGIN', label: _('Mullvad account number'), type: 'text' },
	{ key: 'PERSONAL_PRIVATE_KEY', label: _('WireGuard private key'), type: 'password' },
	{ key: 'PERSONAL_PUBLIC_KEY', label: _('WireGuard public key'), type: 'text' },
	{ key: 'COUNTRY_CODE', label: _('Country code'), type: 'text' },
	{ key: 'EXPECTED_CITY', label: _('Expected city'), type: 'text' },
	{ key: 'EXPECTED_COUNTRY', label: _('Expected country'), type: 'text' },
	{ key: 'OWNED_SERVERS_ONLY', label: _('Owned servers only'), type: 'bool' },
	{ key: 'MULLVAD_SERVER_PORT', label: _('WireGuard port'), type: 'text' },
	{ key: 'NOTIFY_VIA_TELEGRAM', label: _('Notify via Telegram'), type: 'bool' },
	{ key: 'TELEGRAM_BOT_ID', label: _('Telegram bot ID'), type: 'text' },
	{ key: 'TELEGRAM_BOT_TOKEN', label: _('Telegram bot token'), type: 'password' },
	{ key: 'TELEGRAM_CHAT_ID', label: _('Telegram chat ID'), type: 'text' },
	{ key: 'MONITOR_VIA_HEALTHCHECKS', label: _('Monitor via Healthchecks.io'), type: 'bool' },
	{ key: 'HEALTHCHECKS_ID', label: _('Healthchecks.io check ID'), type: 'text' }
];

// The config file is a plain shell script (see README "Create your configuration
// file"): quoted string fields look like export KEY="value" and boolean fields
// are bare export KEY=true|false, both may carry a trailing "# comment".
function fieldRegex(field) {
	var pattern = field.type === 'bool'
		? '^export ' + field.key + '=(true|false)'
		: '^export ' + field.key + '="((?:[^"\\\\]|\\\\.)*)"';
	return new RegExp(pattern, 'm');
}

function parseConfig(text) {
	var values = {};
	CONFIG_FIELDS.forEach(function(f) {
		var m = fieldRegex(f).exec(text || '');
		if (!m) {
			values[f.key] = f.type === 'bool' ? 'false' : '';
		} else if (f.type === 'bool') {
			values[f.key] = m[1];
		} else {
			values[f.key] = m[1].replace(/\\(.)/g, '$1');
		}
	});
	return values;
}

function serializeConfig(text, values) {
	var out = text || '';
	CONFIG_FIELDS.forEach(function(f) {
		var raw = values[f.key] != null ? String(values[f.key]) : '';
		var replacement = f.type === 'bool'
			? 'export ' + f.key + '=' + (raw === 'true' ? 'true' : 'false')
			: 'export ' + f.key + '="' + raw.replace(/\\/g, '\\\\').replace(/"/g, '\\"') + '"';
		var re = fieldRegex(f);
		if (re.test(out))
			out = out.replace(re, replacement);
		else
			out = out.replace(/\n?$/, '\n' + replacement + '\n');
	});
	return out;
}

return view.extend({
	load: function() {
		return Promise.all([
			L.resolveDefault(fs.read(CONFIG_PATH), ''),
			L.resolveDefault(fs.exec_direct(STATUS_SCRIPT, []), ''),
			L.resolveDefault(fs.list(SERVERS_DIR), [])
		]);
	},

	// Runs one of the wrapped shell scripts via ubus/cgi-io. Shared by the
	// Setup and Reconnect buttons.
	runScript: function(path, label) {
		ui.showModal(label, [ E('p', { 'class': 'spinning' }, _('Please wait...')) ]);
		return fs.exec_direct(path, []).then(function(res) {
			ui.hideModal();
			return res;
		}).catch(function(err) {
			ui.hideModal();
			ui.addNotification(null, E('p', label + ' ' + _('failed') + ': ' + err.message), 'error');
			throw err;
		});
	},

	saveConfigValues: function(patch) {
		return fs.read(CONFIG_PATH).then(function(text) {
			var values = parseConfig(text);
			Object.keys(patch).forEach(function(k) { values[k] = patch[k]; });
			return fs.write(CONFIG_PATH, serializeConfig(text, values));
		});
	},

	renderStatusTable: function(status) {
		var rows = [
			[ _('Configured'), status.configured ? _('Yes') : _('No') ],
			[ _('WireGuard interface'), status.wg_interface_present ? _('Present') : _('Missing') ],
			[ _('Behind Mullvad exit'), status.mullvad_exit_ip === true ? _('Yes') : _('No') ],
			[ _('Public IP'), status.ip || '-' ],
			[ _('Location'), (status.city || status.country) ? (status.city + ', ' + status.country) : '-' ],
			[ _('Exit hostname'), status.exit_hostname || '-' ],
			[ _('Active peer'), status.current_peer_description || '-' ],
			[ _('Matches expected location'), status.matches_expected === true ? _('Yes') : _('No') ]
		];

		return E('table', { 'class': 'table' }, rows.map(function(r) {
			return E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [ r[0] ]),
				E('td', { 'class': 'td left' }, [ r[1] ])
			]);
		}));
	},

	renderLogTable: function(status) {
		var lc = status.last_check;
		if (!lc)
			return E('p', {}, _('No health-check log yet.'));

		var when = lc.timestamp ? new Date(lc.timestamp * 1000).toLocaleString() : '-';
		var rows = [
			[ _('Last run'), when ],
			[ _('Result'), lc.ok ? _('OK') : _('Failed (router likely rebooted)') ],
			[ _('Location'), lc.location || '-' ],
			[ _('Expected'), lc.expected_location || '-' ],
			[ _('Source'), lc.source || '-' ]
		];

		return E('table', { 'class': 'table' }, rows.map(function(r) {
			return E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [ r[0] ]),
				E('td', { 'class': 'td left' }, [ r[1] ])
			]);
		}));
	},

	renderServerPicker: function(configValues, serverFiles) {
		var self = this;

		var countrySelect = E('select', { 'class': 'cbi-input-select' }, [
			E('option', { 'value': '' }, _('-- select country --'))
		]);

		(serverFiles || [])
			.filter(function(f) { return f.type === 'file' && /\.json$/.test(f.name); })
			.map(function(f) { return f.name.replace(/\.json$/, ''); })
			.sort()
			.forEach(function(cc) {
				countrySelect.appendChild(E('option', { 'value': cc }, cc.toUpperCase()));
			});

		var citySelect = E('select', { 'class': 'cbi-input-select', 'disabled': true }, [
			E('option', { 'value': '' }, _('-- select country first --'))
		]);

		countrySelect.addEventListener('change', function() {
			var cc = countrySelect.value;
			citySelect.disabled = true;
			citySelect.innerHTML = '';

			if (!cc) {
				citySelect.appendChild(E('option', { 'value': '' }, _('-- select country first --')));
				return;
			}

			citySelect.appendChild(E('option', { 'value': '' }, _('Loading...')));

			fs.read(SERVERS_DIR + '/' + cc + '.json').then(function(data) {
				var servers = JSON.parse(data);
				var seen = {};

				citySelect.innerHTML = '';
				citySelect.appendChild(E('option', { 'value': '' }, _('-- select city --')));

				servers.forEach(function(s) {
					var key = s.city_name + '|' + s.country_name;
					if (seen[key])
						return;
					seen[key] = true;
					citySelect.appendChild(E('option', {
						'value': key,
						'data-city': s.city_name,
						'data-country': s.country_name
					}, s.city_name + ', ' + s.country_name));
				});

				citySelect.disabled = false;
			}).catch(function() {
				citySelect.innerHTML = '';
				citySelect.appendChild(E('option', { 'value': '' }, _('Failed to load server list')));
			});
		});

		var applyBtn = E('button', {
			'class': 'cbi-button cbi-button-apply',
			'click': ui.createHandlerFn(this, function() {
				var cc = countrySelect.value;
				var opt = citySelect.options[citySelect.selectedIndex];

				if (!cc || !opt || !opt.value) {
					ui.addNotification(null, E('p', _('Pick a country and city first.')), 'warning');
					return;
				}

				return self.saveConfigValues({
					COUNTRY_CODE: cc,
					EXPECTED_CITY: opt.getAttribute('data-city'),
					EXPECTED_COUNTRY: opt.getAttribute('data-country')
				}).then(function() {
					return self.runScript(RECONNECT_SCRIPT, _('Reconnecting'));
				}).then(function() {
					location.reload();
				});
			})
		}, [ _('Save and reconnect') ]);

		return E('div', {}, [
			E('p', {}, configValues.EXPECTED_CITY
				? (_('Current: ') + configValues.EXPECTED_CITY + ', ' + configValues.EXPECTED_COUNTRY)
				: _('Not configured yet.')),
			E('div', { 'class': 'cbi-value' }, [
				E('label', { 'class': 'cbi-value-title' }, _('Country')),
				E('div', { 'class': 'cbi-value-field' }, [ countrySelect ])
			]),
			E('div', { 'class': 'cbi-value' }, [
				E('label', { 'class': 'cbi-value-title' }, _('City')),
				E('div', { 'class': 'cbi-value-field' }, [ citySelect ])
			]),
			E('div', { 'class': 'cbi-page-actions' }, [ applyBtn ])
		]);
	},

	renderSettings: function(configText) {
		var self = this;
		var values = parseConfig(configText);
		var inputs = {};

		var rows = CONFIG_FIELDS.map(function(f) {
			var input;
			if (f.type === 'bool') {
				input = E('input', { 'type': 'checkbox' });
				input.checked = (values[f.key] === 'true');
			} else {
				input = E('input', {
					'type': f.type === 'password' ? 'password' : 'text',
					'class': 'cbi-input-text',
					'value': values[f.key] || ''
				});
			}
			inputs[f.key] = input;
			return E('div', { 'class': 'cbi-value' }, [
				E('label', { 'class': 'cbi-value-title' }, f.label),
				E('div', { 'class': 'cbi-value-field' }, [ input ])
			]);
		});

		var saveBtn = E('button', {
			'class': 'cbi-button cbi-button-save',
			'click': ui.createHandlerFn(this, function() {
				var patch = {};
				CONFIG_FIELDS.forEach(function(f) {
					var input = inputs[f.key];
					patch[f.key] = f.type === 'bool' ? String(!!input.checked) : input.value;
				});
				return self.saveConfigValues(patch).then(function() {
					ui.addNotification(null, E('p', _('Configuration saved.')), 'info');
				});
			})
		}, [ _('Save configuration') ]);

		return E('div', {}, rows.concat([
			E('div', { 'class': 'cbi-page-actions' }, [ saveBtn ])
		]));
	},

	render: function(data) {
		var self = this;
		var configText = data[0];
		var status = {};
		var serverFiles = data[2];

		try { status = JSON.parse(data[1] || '{}'); } catch (e) {}

		var configValues = parseConfig(configText);

		var setupBtn = E('button', {
			'class': 'cbi-button cbi-button-action',
			'click': ui.createHandlerFn(this, function() {
				return self.runScript(SETUP_SCRIPT, _('Running setup')).then(function() {
					ui.addNotification(null, E('p', _('Setup finished. The router is rebooting now; this page will stop responding shortly.')), 'info');
				});
			})
		}, [ _('Run setup (reboots router)') ]);

		var reconnectBtn = E('button', {
			'class': 'cbi-button cbi-button-action',
			'click': ui.createHandlerFn(this, function() {
				return self.runScript(RECONNECT_SCRIPT, _('Reconnecting')).then(function() {
					location.reload();
				});
			})
		}, [ _('Reconnect / rotate server') ]);

		var refreshBtn = E('button', {
			'class': 'cbi-button',
			'click': ui.createHandlerFn(this, function() {
				location.reload();
			})
		}, [ _('Refresh') ]);

		return E('div', {}, [
			E('h2', {}, _('Mullvad WireGuard')),

			E('div', { 'class': 'cbi-section' }, [
				E('h3', {}, _('Status')),
				self.renderStatusTable(status),
				E('div', { 'class': 'cbi-page-actions' }, [ setupBtn, ' ', reconnectBtn, ' ', refreshBtn ])
			]),

			E('div', { 'class': 'cbi-section' }, [
				E('h3', {}, _('Server selection')),
				self.renderServerPicker(configValues, serverFiles)
			]),

			E('div', { 'class': 'cbi-section' }, [
				E('h3', {}, _('Configuration')),
				self.renderSettings(configText)
			]),

			E('div', { 'class': 'cbi-section' }, [
				E('h3', {}, _('Last health check')),
				self.renderLogTable(status)
			])
		]);
	},

	handleSave: null,
	handleSaveApply: null,
	handleReset: null
});
