import errno, glob, shutil, logging, os, sys, tempfile

#
# Develop a searchpath for CSS/HTML/JS files and templates:
#
# 1) If the "--cwd" option was specified, the current directory is searched
#    first.
#
# 2) If the VRUN_AUTHOR_PATH environment variable is set, the specified
#    directories are scanned in the order they appear.
#
# 3) The vm_src/vauthor tree Questa install directory is scanned as a last
#    resort in all cases.
#
# 4) The first scanned directory to have a writeable "suites" subdirectory
#    will cause that directory to be used for suite JSON files. If there is
#    writeable "suites" directory, the server will exit with an error.
#

searchpath = []
configpath = ''

def prompt_yes_no(prompt):

	try:
		input = raw_input
	except NameError:
		pass

	while True:
		reply = input(prompt).lower()

		if reply in set(['yes','ye', 'y']):
			return True
		elif reply in set(['no','n']):
			return False
		else:
			prompt = "Please respond with 'yes' or 'no': "

#
# Determines whether a directory is user-writable
#
def is_writable_dir(path):

	try:
		if os.path.isdir(path):
			testfile = tempfile.TemporaryFile(dir = path)
			testfile.close()

			return True

	except OSError as e:
		if e.errno != errno.EACCES: # re-raise unexpected errors
			e.filename = path
			raise

	return False

#
# Finds a file or directory (possibly within a template directory) by searching a pre-determined path
#
# If template is NOT defined, search:
#   searchpath(0), searchpath(1), etc...
#
# If template IS defined, search:
#   searchpath(0), searchpath(0)/templates/<template>, searchpath(1), searchpath(1)/templates/<template>, etc...
#
def find_path(target, template = None):

	logging.debug('find_path called with %s and template %s', target, template)

	# Look for target file/directory in current directory and install directory

	for location in searchpath:
		path = os.path.join(location, target)

		logging.debug('...testing %s', path)

		if os.path.exists(path):
			return path

		if template:
			path = os.path.join(location, 'templates', template, target)

			logging.debug('...testing %s (template)', path)

			if os.path.exists(path):
				return path

	raise IOError(2, 'File "%s" not found' % target)

#
# Finds a writable directory by searching a pre-determined path (including $cwd)
#
def find_writable_dir(target):

	for location in searchpath + [os.getcwd()]:
		path = os.path.join(location, target)

		if is_writable_dir(path):
			return path

	return None

#
# Returns a sorted list of unique template names
#
def templates():

	retval = []

	# Look for templates in current directory and install directory

	for location in searchpath:
		path = os.path.join(location, 'templates')

		retval.extend([name for name in os.listdir(path) if os.path.isdir(os.path.join(path, name))])

	return sorted(set(retval))

#
# Finds a template directory given a template name or a absolute/relative path
#
def find_template_dir(target):

	logging.debug('find_template_dir called with %s', target)

	# Look in the template sub-directory if the source is not a path...

	if '/' not in target:
		return find_path(os.path.join('templates', target))

	return find_path(target)

#
# Returns a list of matching files from the directory where configuration files are saved
#
def dbglob(pattern):
	return glob.glob(os.path.join(configpath, '*.json'))

#
# Returns a path to the configuration file corresponding to a given suite name
#
def dbpath(name):
	return os.path.join(configpath, ('%s.json' % name))

def globpath(name):
	return os.path.join(configpath, ('%s.js' % name))
#
# Initializes search path (must be called first)
#
def init_search_path(envvar, usecwd, suites):
	global searchpath
	global configpath

	#
	# Determine the search path:
	#
	#   1) If the "--cwd" option was specified, the current directory
	#      will be searched first.
	#
	#   2) If the VRUN_AUTHOR_PATH env variable is set, the directories
	#      specified by that variable are added to the path in the order
	#      they appear.
	#
	#   3) The vm_src/vauthor tree in the Questa install directory is
	#      always added as a last resort.
	#

	if usecwd:
		searchpath.append(os.getcwd())

	if envvar in os.environ:
		searchpath.extend(os.environ.get(envvar).strip().split(':'))

	searchpath.append(os.path.abspath(os.path.join(os.path.dirname(sys.argv[0]), '..')))

	#
	# Determine the location of the JSON configuration files
	#
	#   4) If the "--suites" option was specified, use that directory for
	#      the configpath, bypassing any search.
	#
	#   5) Lacking that, scan the search path for a writeable "suites"
	#      subdirectory.
	#
	#   6) If no writeable "suites" directory has been found, use the
	#      current directory as a last resort (even if "--cwd" was not
	#      specified).
	#
	#   7) If the directory so determined does not exist, offer to create
	#      the directory.
	#
	#   8) If the directory so found/created is not writeable, error out.
	#

	configpath = os.path.join(os.getcwd(), suites) if suites else find_writable_dir('suites');

	if not configpath:
		configpath = os.path.join(os.getcwd(), 'suites');

	if not is_writable_dir(configpath):
		if os.path.isdir(configpath):
			raise RuntimeError('Suites directory {0} exists but is not writeable! You can use "-suites" option to specify a different suites directory'.format(configpath))

		elif os.path.isfile(configpath):
			raise RuntimeError('Suites path {0} exists but is not a directory! You can use "-suites" option to specify a different suites directory'.format(configpath))

		else:
			print 'Suites directory does not exist. Creating suites directory...'
			os.makedirs(configpath)
			globalpath = os.path.join(configpath, 'global.js')
			globaltmppath = find_path('templates/global.js')
			shutil.copyfile(globaltmppath, globalpath)

	else:
		print 'Using existing suites directory at '.format(configpath)
		globalpath = os.path.join(configpath, 'global.js')
		if not os.path.isfile(globalpath):
			globaltmppath = find_path('templates/global.js')
			shutil.copyfile(globaltmppath, globalpath)

	print 'Search path: {0}'.format(searchpath)
	print 'Config path: {0}'.format(configpath)

def init_log_file(log_file):
	if not log_file:
		log_file_name = 'author_{0}.log'.format(os.getpid())
		log_file = os.path.join(os.getcwd(), log_file_name)
	print 'Redirecting output to {0} ...'.format(log_file)
	so = se = open(log_file, 'w', 0)
	sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
	sys.stderr = os.fdopen(sys.stderr.fileno(), 'w', 0)
	os.dup2(so.fileno(), sys.stdout.fileno())
	os.dup2(se.fileno(), sys.stderr.fileno())
