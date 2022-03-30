import os, json, logging, vrmutils

##
##   rmdbdata.suites()               -- returns directory of available suites
##   rmdbdata.create(name, template) -- create a new suite
##   rmdbdata.delete(name)           -- delete the specified suite
##
##   suite.get(name, attr)           -- returns value of attr from suite
##   suite.set(name, attr, value)    -- sets value of attr in suite and saves
##   suite.save(name)                -- saves suite to json file
##   suite._lastget(name, key, value) -- returns value of attribute from suite or global
##

def suites():
	retval = []

	for file in vrmutils.dbglob('*.json'):
		tempdata = json.load(open(file, 'r'))

		if 'template' in tempdata:
			retval.append({"name": os.path.splitext(os.path.basename(file))[0], "template": tempdata['template']})

	return sorted(retval)

def create(name, template):
	data = RmdbData(name, template)

def delete(name):
	file = vrmutils.dbpath(name)

	data = RmdbData(name)
	data.delete(name)

	logging.debug('Attempting to delete %s', file)

	if os.path.exists(file):
		os.remove(file)

		logging.debug('...deleted %s', file)

class RmdbData(object):

	cache = {} # cache of loaded RmdbData objects
	cachehelp = {}
	def delete(self, name):
		del self.cache[name]

	def dump(self):
		return self.cache[self.name];

	def load(self, name, path):
		self.cache[name] = {}

		try:
			with open(path, 'r') as fp:
				self.cache[name] = json.load(fp)

		except IOError:
			logging.debug('Data file %s doesn\'t exist or can\'t be read', path)
		# with open(os.path.join(os.getcwd(), ('%s.asread' % name)), 'w') as f:
		# 	json.dump(self.cache[name], f, sort_keys=True, indent=4)

	def loadhelp(self, name, path):
		self.cachehelp[name] = {}
		try:
			with open(path, 'r') as fp:
				self.cachehelp[name] = json.load(fp)

		except IOError:
			logging.debug('Data file %s doesn\'t exist or can\'t be read', path)

	def __init__(self, name, template = None):
		self.name = name
		# Load the data file into the cache if it's not already there...
		if 'global' not in self.cache:
			self.load('global', vrmutils.globpath('global'))
		if 'globalhelp' not in self.cachehelp:
			self.loadhelp('globalhelp', os.path.join(vrmutils.find_template_dir(''),'globalhelp.js'))
		if name not in self.cache:
			self.load(name, vrmutils.dbpath(name))
			self.put('suite', name) # override suite name
		# Seed the data file with template data the first time
		if template or self.get('template') != None:
			if template:
				templatehelp = template + "help"
			else:
				templatehelp = str(self.get('template'))+'help'
			if templatehelp not in self.cachehelp:	
				self.loadhelp(templatehelp, os.path.join(vrmutils.find_template_dir(templatehelp[:-4]), templatehelp +'.js'))
		if template and self.get('template') == None:
			self.load(name, os.path.join(vrmutils.find_template_dir(template), 'data.json'))
			self.put('template', template) # override template name

			self.save()
	def _put(self, node, keys, value):
		if len(keys) > 1:
			if not keys[0] in node:
				node[keys[0]] = {}

			self._put(node[keys[0]], keys[1:], value)

		elif len(keys) > 0:
			node[keys[0]] = value

	def put(self, key, value):
		self._put(self.cache[self.name], key.split('.'), value)

	def _lastget(self, node, keys, default):
		if not keys[0] in node:
			return default
		elif len(keys) > 1:
                        return self._lastget(node[keys[0]], keys[1:], default)
                else:
                        return node[keys[0]]
	
	def _get(self, node, globalnode, keys, default):
		if keys[0] in node:
			return self._lastget(node, keys, default)
		if keys[0] in globalnode:
			return self._lastget(globalnode, keys, default)
		else:
			return default

	def get(self, key, default = None):
		return self._get(self.cache[self.name], self.cache['global'], key.split('.'), default)

	def gethelp(self, key, default = None):
		if self.name == 'global':
			return self._get(self.cachehelp['globalhelp'], self.cachehelp['globalhelp'], key.split('.'), default)
		return self._get(self.cachehelp[str(self.get('template'))+'help'], self.cachehelp['globalhelp'], key.split('.'), default)
		

	def save(self):
		filepath = vrmutils.globpath('global') if self.name=='global' else vrmutils.dbpath(self.name)
		with open(filepath, 'w') as f:
			json.dump(self.cache[self.name], f, sort_keys=True, indent=4)

	def to_string(self):
		return json.dumps(self.cache[self.name], sort_keys=True, indent=4)

	def test_get(self, key):
		print 'Key:', key, 'is', self.get(key, '<null>')
